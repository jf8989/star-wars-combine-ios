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

    // Keep a snapshot of the browsing list so we can restore it after search clears
    private var browsingPlanets: [Planet] = []

    // Expose whether a next page exists (for the "Next" button)
    public var canLoadMore: Bool {
        mode == .browsing && nextURL != nil && !isLoading
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
                    self.planets = page.planets
                    self.browsingPlanets = page.planets
                    self.nextURL = page.next
                }
            )
    }

    public func loadNextPageIfNeeded(currentIndex: Int) {
        guard mode == .browsing,
            let url = nextURL,
            !isLoading,
            currentIndex >= planets.count - 1
        else { return }

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
                planets = browsingPlanets
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
