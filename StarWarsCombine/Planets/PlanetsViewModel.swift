// App/Planets/PlanetsViewModel.swift

import Combine
import Foundation

final class PlanetsViewModel: ObservableObject {
    // MARK: - Published UI state
    @Published private(set) var displayPlanets: [Planet] = []
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
    var hasServerPaging: Bool { nextURL != nil }

    /// Prev/Next availability
    var canLoadMore: Bool {
        guard mode == .browsing, !isLoading else { return false }
        if hasServerPaging { return true }
        return pager.hasNext(totalCount: browsingPlanets.count)
    }

    var currentPageDisplay: Int { currentPage + 1 }

    var totalPagesDisplay: String {
        if hasServerPaging {
            // Unknown until server no longer reports `next`
            return "?"
        } else {
            return String(pager.totalPages(totalCount: browsingPlanets.count))
        }
    }

    // MARK: - Debounce latency
    private let debounceInterval: DispatchQueue.SchedulerTimeType.Stride
    private let debounceScheduler: DispatchQueue

    // MARK: - Init
    init(
        service: PlanetsService,
        debounceInterval: DispatchQueue.SchedulerTimeType.Stride = .milliseconds(300),
        debounceScheduler: DispatchQueue = .main
    ) {
        self.service = service
        self.debounceInterval = debounceInterval
        self.debounceScheduler = debounceScheduler
        bindSearchPipeline()
    }

    // MARK: - Intents (Browsing)
    func loadFirstPage() {
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
                    self.displayPlanets = self.pager.slice(browsingPlanets)
                    self.isLoading = false
                }
            )
    }

    func goNextPage() {
        guard mode == .browsing else { return }
        pageDirection = .forward

        // If we already have enough items locally, move the pager forward.
        if pager.stepForwardIfPossible(totalCount: browsingPlanets.count) {
            currentPage = pager.currentPage
            displayPlanets = pager.slice(browsingPlanets)
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
                    self.displayPlanets = self.pager.slice(self.browsingPlanets)
                }
            )
    }

    func goPrevPage() {
        guard mode == .browsing else { return }
        pageDirection = .backward
        if pager.stepBackward() {
            currentPage = pager.currentPage
            displayPlanets = pager.slice(browsingPlanets)
        }
    }

    // MARK: - Search (Extra Credit)
    private func bindSearchPipeline() {
        $searchTerm
            .debounce(for: debounceInterval, scheduler: debounceScheduler)
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
            displayPlanets = pager.slice(browsingPlanets)
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
                    self?.displayPlanets = results
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
