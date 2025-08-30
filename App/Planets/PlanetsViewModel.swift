// App/Planets/PlanetsViewModel.swift

import Combine
import Foundation

/// ViewModel for the Planets screen.
/// - Paging using SWAPI's `next` URL
/// - Loading + alert mapping
/// - Extra Credit: debounced remote search on same list surface
@MainActor
public final class PlanetsViewModel: ObservableObject {
    // Published UI state
    @Published public private(set) var planets: [Planet] = []
    @Published public private(set) var isLoading: Bool = false
    @Published public var alert: String? = nil
    @Published public var searchTerm: String = ""
    @Published public private(set) var mode: Mode = .browsing

    public enum Mode { case browsing, searching }

    // Dependencies
    private let service: PlanetsService
    private let bag = TaskBag()

    // Paging
    private var nextURL: URL?
    private var pagingCancellable: AnyCancellable?
    private var searchCancellable: AnyCancellable?

    // Browsing snapshot (all items we've fetched so far)
    private var browsingPlanets: [Planet] = []

    // Client-side paging state (used when nextURL == nil)
    private let clientPageSize = 10
    private var clientPage = 1

    // Can we load more? (server OR client)
    public var canLoadMore: Bool {
        guard mode == .browsing, !isLoading else { return false }
        if nextURL != nil { return true }  // server paging available
        return browsingPlanets.count > planets.count  // client paging
    }

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
                    guard let self else { return }
                    self.isLoading = false
                    if case .failure(let err) = completion {
                        self.alert = err.userMessage
                    }
                },
                receiveValue: { [weak self] page in
                    guard let self else { return }
                    self.browsingPlanets = page.planets
                    self.nextURL = page.next
                    // Show first slice (client) or whole first page (server)
                    if self.nextURL == nil {
                        self.clientPage = 1
                        self.planets = Array(
                            self.browsingPlanets.prefix(self.clientPageSize)
                        )
                    } else {
                        self.planets = page.planets
                    }
                }
            )
    }

    public func loadNextPageIfNeeded(currentIndex: Int) {
        guard mode == .browsing, !isLoading else { return }

        // Server paging path
        if let url = nextURL {
            guard currentIndex >= planets.count - 1 else { return }
            isLoading = true
            pagingCancellable = service.fetchPage(at: url)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { [weak self] completion in
                        guard let self else { return }
                        self.isLoading = false
                        if case .failure(let err) = completion {
                            self.alert = err.userMessage
                        }
                    },
                    receiveValue: { [weak self] page in
                        guard let self else { return }
                        self.planets.append(contentsOf: page.planets)
                        self.browsingPlanets = self.planets
                        self.nextURL = page.next
                    }
                )
            return
        }

        // Client paging path (no server `next`)
        guard currentIndex >= planets.count - 1 else { return }
        let nextCount = min(
            browsingPlanets.count,
            (clientPage + 1) * clientPageSize
        )
        if nextCount > planets.count {
            clientPage += 1
            planets = Array(browsingPlanets.prefix(nextCount))
        }
    }

    // MARK: - Search (Extra Credit)

    private func bindSearchPipeline() {
        $searchTerm
            .debounce(for: .milliseconds(350), scheduler: DispatchQueue.main)
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
            // Restore the last known browsing list; fetch only if we truly have nothing.
            mode = .browsing
            if browsingPlanets.isEmpty {
                if planets.isEmpty { loadFirstPage() }
            } else {
                // Restore client/server paging presentation
                if nextURL == nil {
                    clientPage = max(1, clientPage)  // keep current page count
                    let count = min(
                        browsingPlanets.count,
                        clientPage * clientPageSize
                    )
                    planets = Array(browsingPlanets.prefix(count))
                } else {
                    planets = browsingPlanets
                }
            }
            return
        }

        mode = .searching
        isLoading = true
        searchCancellable = service.searchPlanets(query: q)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self else { return }
                    self.isLoading = false
                    if case .failure(let err) = completion {
                        self.alert = err.userMessage
                    }
                },
                receiveValue: { [weak self] page in
                    self?.planets = page.planets
                }
            )
    }
}
