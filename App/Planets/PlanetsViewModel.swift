// App/Planets/PlanetsViewModel.swift

import Combine
import Foundation

/// ViewModel for the Planets screen.
/// - Page-turn UX via PlanetsPager (client-side slicing), also works with server `next`
/// - Loading + alert mapping
/// - Debounced search (service-backed) that preserves paging slice on clear
@MainActor
public final class PlanetsViewModel: ObservableObject {
    // MARK: - Published UI state
    @Published private(set) var planets: [Planet] = []
    @Published private(set) var isLoading: Bool = false
    @Published var alert: String? = nil
    @Published var searchTerm: String = ""
    @Published private(set) var mode: Mode = .browsing
    @Published private(set) var currentPage: Int = 0  // mirror of pager.currentPage for animations
    @Published private(set) var pageDirection: PageDirection = .forward

    enum Mode { case browsing, searching }
    enum PageDirection { case forward, backward }

    // MARK: - Dependencies
    private let service: PlanetsService
    private let bag = TaskBag()

    // MARK: - Paging (server + client)
    private var nextURL: URL?
    private var pagingCancellable: AnyCancellable?
    private var searchCancellable: AnyCancellable?

    // All items fetched/known so far (browsing mode)
    private var browsingPlanets: [Planet] = []

    // Extracted pager (pure)
    private var pager = PlanetsPager(pageSize: 10)

    // MARK: - Derived UI props
    /// True only when the API exposes a `next` URL (open-ended set).
    public var hasServerPaging: Bool { nextURL != nil }

    /// Prev/Next availability
    public var canLoadMore: Bool {
        guard mode == .browsing, !isLoading else { return false }
        if hasServerPaging { return true }
        return pager.hasNext(totalCount: browsingPlanets.count)
    }

    public var currentPageDisplay: Int { currentPage + 1 }

    public var totalPagesDisplay: String {
        if hasServerPaging {
            // Unknown until server no longer reports `next`
            return "?"
        } else {
            return String(pager.totalPages(totalCount: browsingPlanets.count))
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
                    guard let self else { return }
                    // alpha sort is a presentation choice → helper
                    self.browsingPlanets = PlanetsSorting.alpha(page.planets)
                    self.nextURL = page.next
                    self.pager.reset()
                    self.currentPage = pager.currentPage
                    self.planets = self.pager.slice(browsingPlanets)
                    self.isLoading = false
                }
            )
    }

    public func goNextPage() {
        guard mode == .browsing else { return }
        pageDirection = .forward

        // If we already have enough items locally, move the pager forward.
        if pager.stepForwardIfPossible(totalCount: browsingPlanets.count) {
            currentPage = pager.currentPage
            planets = pager.slice(browsingPlanets)
            return
        }

        // Otherwise, fetch the next server page if present, then advance.
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
                    self.browsingPlanets.append(contentsOf: page.planets)
                    self.browsingPlanets = PlanetsSorting.alpha(
                        self.browsingPlanets
                    )
                    self.nextURL = page.next
                    _ = self.pager.stepForwardIfPossible(
                        totalCount: self.browsingPlanets.count
                    )
                    self.currentPage = self.pager.currentPage
                    self.planets = self.pager.slice(self.browsingPlanets)
                }
            )
    }

    public func goPrevPage() {
        guard mode == .browsing else { return }
        pageDirection = .backward
        if pager.stepBackward() {
            currentPage = pager.currentPage
            planets = pager.slice(browsingPlanets)
        }
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
        let trimmedTerm = term.trimmingCharacters(in: .whitespacesAndNewlines)

        // Cancel any in-flight search
        searchCancellable?.cancel()

        guard !trimmedTerm.isEmpty else {
            // Restore the current browsing slice without refetching
            mode = .browsing
            planets = pager.slice(browsingPlanets)
            return
        }

        mode = .searching
        isLoading = true
        searchCancellable = service.searchPlanets(query: trimmedTerm)
            .receive(on: DispatchQueue.main)
            .map { PlanetsSorting.alpha($0.planets) }
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.finishLoading(with: completion)
                },
                receiveValue: { [weak self] results in
                    self?.planets = results
                }
            )
    }

    // MARK: - Helpers
    private func finishLoading(
        with completion: Subscribers.Completion<AppError>
    ) {
        isLoading = false
        if case .failure(let err) = completion { alert = err.userMessage }
    }
}
