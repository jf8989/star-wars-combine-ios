// App/Engine/Services/LocalSearchPlanetsService.swift

import Combine
import Foundation

/// Decorator over a real PlanetsService that:
/// - Passes through network fetches
/// - Builds an in-memory index of all seen planets (session-only)
/// - Implements `searchPlanets` by filtering that index,
///   while optionally backfilling remaining pages in the background.
///
/// This preserves the "feels like the same API" contract: callers still use
/// PlanetsService, and `searchPlanets` returns an AnyPublisher<PlanetsPage, AppError>.
public final class LocalSearchPlanetsService: PlanetsService {
    private let base: PlanetsService
    private var fakeAPIlocalPlanetIndex: [Planet] = []
    private var seenNames = Set<String>()  // simple de-dupe
    private var nextURL: URL?  // last known next from pass-through pages
    private var isBackfilling = false
    private var cancellables = Set<AnyCancellable>()  // internal Combine bag
    private let indexQueue = DispatchQueue(
        label: "LocalSearch.Index",
        qos: .userInitiated
    )

    /// Optional artificial latency to make search feel like a real API.
    private let searchLatency: DispatchQueue.SchedulerTimeType.Stride =
        .milliseconds(120)

    private let backfillAll: Bool

    public init(base: PlanetsService, backfillAll: Bool = false) {
        self.base = base
        self.backfillAll = backfillAll
    }

    // MARK: - PlanetsService

    public func fetchFirstPage() -> AnyPublisher<PlanetsPage, AppError> {
        base.fetchFirstPage()
            .handleEvents(receiveOutput: { [weak self] page in
                self?.ingest(page)
            })
            .eraseToAnyPublisher()
    }

    public func fetchPage(at url: URL) -> AnyPublisher<PlanetsPage, AppError> {
        base.fetchPage(at: url)
            .handleEvents(receiveOutput: { [weak self] page in
                self?.ingest(page)
            })
            .eraseToAnyPublisher()
    }

    public func searchPlanets(query: String) -> AnyPublisher<
        PlanetsPage, AppError
    > {
        // Kick a background backfill if we know there are more pages.
        triggerBackfillIfNeeded()

        let result = filter(query)
        // Wrap results to look like a network call.
        return Just(PlanetsPage(next: nil, planets: result))
            .delay(for: searchLatency, scheduler: DispatchQueue.main)
            .setFailureType(to: AppError.self)
            .eraseToAnyPublisher()
    }

    // MARK: - Indexing

    private func ingest(_ page: PlanetsPage) {
        indexQueue.async { [weak self] in
            guard let self else { return }
            for planet in page.planets where self.seenNames.insert(planet.name).inserted {
                self.fakeAPIlocalPlanetIndex.append(planet)
            }
            self.nextURL = page.next
        }
    }

    private func filter(_ query: String) -> [Planet] {
        let searchTerm = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !searchTerm.isEmpty else { return snapshotIndex() }
        let compareOptions: String.CompareOptions = [
            .caseInsensitive, .diacriticInsensitive,
        ]
        return snapshotIndex().filter { planet in
            planet.name.range(of: searchTerm, options: compareOptions) != nil
                || planet.climate.range(of: searchTerm, options: compareOptions) != nil
                || planet.terrain.range(of: searchTerm, options: compareOptions) != nil
        }
    }

    private func snapshotIndex() -> [Planet] {
        var snapshot: [Planet] = []
        indexQueue.sync { snapshot = self.fakeAPIlocalPlanetIndex }
        return snapshot
    }

    // MARK: - Background backfill (memory-only; no persistence)

    private func triggerBackfillIfNeeded() {
        guard backfillAll else { return }  // honor single-call policy
        indexQueue.async { [weak self] in
            guard let self, !self.isBackfilling, let url = self.nextURL else {
                return
            }
            self.isBackfilling = true
            self.walk(from: url)
        }
    }

    private func walk(from url: URL) {
        base.fetchPage(at: url)
            .receive(on: indexQueue)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self else { return }
                    if case .failure = completion {
                        // Stop backfill on error; future searches can retry trigger.
                        self.isBackfilling = false
                    }
                },
                receiveValue: { [weak self] page in
                    guard let self else { return }
                    self.ingest(page)
                    if let next = page.next {
                        self.walk(from: next)
                    } else {
                        self.isBackfilling = false
                    }
                }
            )
            .store(in: &cancellables)
    }
}
