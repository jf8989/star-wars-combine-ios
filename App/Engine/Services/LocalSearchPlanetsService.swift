import Combine
// Engine/Services/LocalSearchPlanetsService.swift
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
    private var index: [Planet] = []
    private var seenNames = Set<String>()  // simple de-dupe
    private var nextURL: URL?  // last known next from pass-through pages
    private var isBackfilling = false
    private var bag = Set<AnyCancellable>()  // internal Combine bag
    private let queue = DispatchQueue(
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
        queue.async { [weak self] in
            guard let self else { return }
            for p in page.planets where self.seenNames.insert(p.name).inserted {
                self.index.append(p)
            }
            self.nextURL = page.next
        }
    }

    private func filter(_ q: String) -> [Planet] {
        let needle = q.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return snapshotIndex() }
        let opts: String.CompareOptions = [
            .caseInsensitive, .diacriticInsensitive,
        ]
        return snapshotIndex().filter { p in
            p.name.range(of: needle, options: opts) != nil
                || p.climate.range(of: needle, options: opts) != nil
                || p.terrain.range(of: needle, options: opts) != nil
        }
    }

    private func snapshotIndex() -> [Planet] {
        var copy: [Planet] = []
        queue.sync { copy = self.index }
        return copy
    }

    // MARK: - Background backfill (memory-only; no persistence)

    private func triggerBackfillIfNeeded() {
        guard backfillAll else { return }  // honor single-call policy
        queue.async { [weak self] in
            guard let self, !self.isBackfilling, let url = self.nextURL else {
                return
            }
            self.isBackfilling = true
            self.walk(from: url)
        }
    }

    private func walk(from url: URL) {
        base.fetchPage(at: url)
            .receive(on: queue)
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
            .store(in: &bag)
    }
}
