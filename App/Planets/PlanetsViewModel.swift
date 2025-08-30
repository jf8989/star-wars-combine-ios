// File: /App/Planets/PlanetsViewModel.swift

import Combine
import Foundation

/// ViewModel for the Planets screen.
/// - Page-turn UX (client-side slicing) that also works with server paging via `next`
/// - Loading + alert mapping
/// - Extra Credit: debounced search that preserves paging slice on clear
@MainActor
public final class PlanetsViewModel: ObservableObject {
    // MARK: - Published UI state
    @Published public private(set) var planets: [Planet] = []
    @Published public private(set) var isLoading: Bool = false
    @Published public var alert: String? = nil
    @Published public var searchTerm: String = ""
    @Published public private(set) var mode: Mode = .browsing
    @Published public private(set) var currentPage: Int = 0  // 0-based
    @Published public private(set) var pageDirection: PageDirection = .forward

    public enum Mode { case browsing, searching }
    public enum PageDirection { case forward, backward }

    // MARK: - Dependencies
    private let service: PlanetsService
    private let bag = TaskBag()

    // MARK: - Paging (server + client)
    private var nextURL: URL?
    private var pagingCancellable: AnyCancellable?
    private var searchCancellable: AnyCancellable?

    // Browsing snapshot (all items fetched/known so far)
    private var browsingPlanets: [Planet] = []

    // Page-turn config (client-side slice size)
    private let pageSize = 10

    // Can we load more? (server OR client)
    public var canLoadMore: Bool {
        guard mode == .browsing, !isLoading else { return false }
        if nextURL != nil { return true }  // server paging available
        return (currentPage + 1) * pageSize < browsingPlanets.count  // client paging
    }

    /// True only when the API exposes a `next` URL.
    public var hasServerPaging: Bool { nextURL != nil }

    /// UI indicator: current page number (1-based)
    public var currentPageDisplay: Int { currentPage + 1 }

    /// UI indicator: total pages. For server paging we show "?" until `next` is nil.
    public var totalPagesDisplay: String {
        if hasServerPaging {
            if nextURL == nil {
                let total = max(
                    1,
                    Int(ceil(Double(browsingPlanets.count) / Double(pageSize)))
                )
                return String(total)
            } else {
                return "?"
            }
        } else {
            let total = max(
                1,
                Int(ceil(Double(browsingPlanets.count) / Double(pageSize)))
            )
            return String(total)
        }
    }

    // MARK: - Init
    public init(service: PlanetsService) {
        self.service = service
        bindSearchPipeline()
    }

    // MARK: - Intents (Browsing)
    public func loadFirstPage() {
        guard mode == .browsing, !isLoading else { return }
        isLoading = true
        pagingCancellable?.cancel()

        pagingCancellable = service.fetchFirstPage()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.finishLoading(with: completion)
                },
                receiveValue: { [weak self] page in
                    self?.ingestFirst(page: page)
                }
            )
    }

    public func goNextPage() {
        guard mode == .browsing else { return }
        pageDirection = .forward

        // If we already have enough items locally for the next slice, page forward.
        let nextStart = (currentPage + 1) * pageSize
        if nextStart < browsingPlanets.count {
            currentPage += 1
            planets = sliceForCurrentPage()
            return
        }

        // Otherwise, fetch the next server page if present; then advance.
        guard let url = nextURL, !isLoading else { return }
        isLoading = true
        pagingCancellable = service.fetchPage(at: url)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.finishLoading(with: completion)
                },
                receiveValue: { [weak self] page in
                    guard let self else { return }
                    // Merge, then keep global alphabetical order
                    self.browsingPlanets.append(contentsOf: page.planets)
                    self.browsingPlanets = self.sorted(self.browsingPlanets)
                    self.nextURL = page.next
                    self.currentPage += 1
                    self.planets = self.sliceForCurrentPage()
                }
            )
    }

    public func goPrevPage() {
        guard mode == .browsing, currentPage > 0 else { return }
        pageDirection = .backward
        currentPage -= 1
        planets = sliceForCurrentPage()
    }

    // MARK: - Search (Extra Credit)
    private func bindSearchPipeline() {
        $searchTerm
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] term in
                self?.performSearch(term)
            }
            .store(in: bag)
    }

    private func performSearch(_ term: String) {
        let q = term.trimmingCharacters(in: .whitespacesAndNewlines)

        // Cancel any in-flight search
        searchCancellable?.cancel()

        guard !q.isEmpty else {
            // Restore the current browsing slice without refetching
            mode = .browsing
            planets = sliceForCurrentPage()
            return
        }

        mode = .searching
        isLoading = true
        searchCancellable = service.searchPlanets(query: q)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.finishLoading(with: completion)
                },
                receiveValue: { [weak self] page in
                    self?.planets = self?.sorted(page.planets) ?? page.planets
                }
            )
    }

    // MARK: - Helpers
    private func sorted(_ items: [Planet]) -> [Planet] {
        items.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name)
                == .orderedAscending
        }
    }

    private func sliceForCurrentPage() -> [Planet] {
        let start = currentPage * pageSize
        let end = min(browsingPlanets.count, start + pageSize)
        guard start < end else { return [] }
        return Array(browsingPlanets[start..<end])
    }

    private func ingestFirst(page: PlanetsPage) {
        browsingPlanets = sorted(page.planets)
        nextURL = page.next
        currentPage = 0
        planets = sliceForCurrentPage()
        isLoading = false
    }

    private func finishLoading(
        with completion: Subscribers.Completion<AppError>
    ) {
        isLoading = false
        if case .failure(let err) = completion { alert = err.userMessage }
    }
}
