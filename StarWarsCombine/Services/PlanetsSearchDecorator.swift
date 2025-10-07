// Path: StarWarsCombine/Services/PlanetsSearchDecorator.swift
// Role: Decorator that simulates API search using a local index and Combine

import Combine
import Foundation

public final class PlanetsSearchDecorator: PlanetsService {
    private let base: PlanetsService

    // Session-only index and simple de-duplication by planet name
    private var indexedPlanets: [Planet] = []
    private var seenPlanetNames = Set<String>()

    // Coordination for index access
    private let indexQueue: DispatchQueue

    // Simulation controls
    private let scheduler: DispatchQueue
    private let latency: DispatchQueue.SchedulerTimeType.Stride

    // One-shot failure injection for tests
    private var nextSearchFailure: AppError?

    init(
        base: PlanetsService,
        scheduler: DispatchQueue = .main,
        latency: DispatchQueue.SchedulerTimeType.Stride = .milliseconds(120),
        indexQueue: DispatchQueue = DispatchQueue(label: "PlanetsSearch.Index", qos: .userInitiated)
    ) {
        self.base = base
        self.scheduler = scheduler
        self.latency = latency
        self.indexQueue = indexQueue
    }

    // MARK: - PlanetsService (pass-through + ingest)
    func fetchFirstPage() -> AnyPublisher<PlanetsPage, AppError> {
        base.fetchFirstPage()
            .handleEvents(receiveOutput: { [weak self] page in
                self?.ingest(page)
            })
            .eraseToAnyPublisher()
    }

    func fetchPage(at url: URL) -> AnyPublisher<PlanetsPage, AppError> {
        base.fetchPage(at: url)
            .handleEvents(receiveOutput: { [weak self] page in
                self?.ingest(page)
            })
            .eraseToAnyPublisher()
    }

    // MARK: - Simulated API search (local filter + publisher)
    func searchPlanets(query: String) -> AnyPublisher<PlanetsPage, AppError> {
        // Test hook: force next search to fail, once
        if let injectedError = nextSearchFailure {
            nextSearchFailure = nil
            return Fail(error: injectedError).eraseToAnyPublisher()
        }

        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let snapshot = snapshotIndex()

        let filtered: [Planet]
        if trimmedQuery.isEmpty {
            filtered = snapshot
        } else {
            let compareOptions: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]
            filtered = snapshot.filter { planet in
                planet.name.range(of: trimmedQuery, options: compareOptions) != nil
                    || planet.climate.range(of: trimmedQuery, options: compareOptions) != nil
                    || planet.terrain.range(of: trimmedQuery, options: compareOptions) != nil
            }
        }

        let page = PlanetsPage(next: nil, planets: filtered)

        // Wrap in a publisher and delay to feel like network (set latency .zero in tests)
        return Just(page)
            .delay(for: latency, scheduler: scheduler)
            .setFailureType(to: AppError.self)
            .eraseToAnyPublisher()
    }

    // MARK: - Test utilities
    public func setNextSearchFailure(_ error: AppError) {
        nextSearchFailure = error
    }

    // MARK: - Indexing

    private func ingest(_ page: PlanetsPage) {
        indexQueue.async { [weak self] in
            guard let self else { return }
            for planet in page.planets {
                if self.seenPlanetNames.insert(planet.name).inserted {
                    self.indexedPlanets.append(planet)
                }
            }
        }
    }

    private func snapshotIndex() -> [Planet] {
        var snapshot: [Planet] = []
        indexQueue.sync {
            snapshot = self.indexedPlanets
        }
        return snapshot
    }
}
