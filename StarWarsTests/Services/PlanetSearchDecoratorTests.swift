// Path: StarWarsTests/Services/PlanetsSearchDecoratorTests.swift
// Role: Local index ingest + search behavior (zero-latency, deterministic)

import Combine
import XCTest

@testable import StarWarsCombine

final class PlanetsSearchDecoratorTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()

    func testIngestsAndDeduplicates_OnFetches() {
        // Given: base stub returns two pages with a duplicate name; decorator ingests on fetches
        let baseService = StubPlanetsService()
        let indexQueue = DispatchQueue(label: "Test.Index")
        let decorator = PlanetsSearchDecorator(
            base: baseService,
            scheduler: .main,
            latency: .zero,
            indexQueue: indexQueue
        )

        let firstPage = PlanetsPage(
            next: URL(string: "https://example.com/next"),
            planets: [
                Planet(
                    name: "Alderaan",
                    climate: "temperate",
                    gravity: "1",
                    terrain: "grasslands",
                    diameter: "12500",
                    population: "2000000000"
                ),
                Planet(
                    name: "Tatooine",
                    climate: "arid",
                    gravity: "1",
                    terrain: "desert",
                    diameter: "10465",
                    population: "200000"
                ),
            ]
        )
        let secondPage = PlanetsPage(
            next: nil,
            planets: [
                Planet(
                    name: "Tatooine",
                    climate: "arid",
                    gravity: "1",
                    terrain: "desert",
                    diameter: "10465",
                    population: "200000"
                ),  // duplicate by name
                Planet(
                    name: "Endor",
                    climate: "temperate",
                    gravity: "0.85",
                    terrain: "forest",
                    diameter: "4900",
                    population: "30000000"
                ),
            ]
        )
        baseService.firstPage = firstPage
        baseService.nextPage = secondPage

        let expectationPagesIngested = expectation(description: "ingest pages")
        var receivedPlanets: [Planet] = []

        // When: fetch first, then fetch next; wait for index queue to drain
        decorator.fetchFirstPage()
            .flatMap { _ in decorator.fetchPage(at: URL(string: "https://example.com/next")!) }
            .sink(
                receiveCompletion: { _ in
                    indexQueue.sync {}  // Then: ensure indexing finished before assertions
                    expectationPagesIngested.fulfill()
                },
                receiveValue: { _ in }
            )
            .store(in: &subscriptions)

        wait(for: [expectationPagesIngested], timeout: 1.0)

        // When: searching with empty string (return all)
        let expectationSearchAll = expectation(description: "search all")
        decorator.searchPlanets(query: "")
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { page in
                    receivedPlanets = page.planets
                    expectationSearchAll.fulfill()
                }
            )
            .store(in: &subscriptions)

        wait(for: [expectationSearchAll], timeout: 1.0)

        // Then: 3 unique names, any order (decorator does not sort)
        XCTAssertEqual(Set(receivedPlanets.map(\.name)), Set(["Alderaan", "Tatooine", "Endor"]))
    }

    func testSearch_FiltersByNameClimateTerrain_CaseAndDiacriticInsensitive() {
        // Given: page containing names and fields with mixed case/diacritics; ingested into decorator
        let baseService = StubPlanetsService()
        let indexQueue = DispatchQueue(label: "Test.Index")
        let decorator = PlanetsSearchDecorator(
            base: baseService,
            scheduler: .main,
            latency: .zero,
            indexQueue: indexQueue
        )

        let page = PlanetsPage(
            next: nil,
            planets: [
                Planet(
                    name: "Endor",
                    climate: "Temperáte",
                    gravity: "0.85",
                    terrain: "Forest",
                    diameter: "4900",
                    population: "30000000"
                ),
                Planet(
                    name: "Hoth",
                    climate: "Frozen",
                    gravity: "1.1",
                    terrain: "Túndra",
                    diameter: "7200",
                    population: "unknown"
                ),
                Planet(
                    name: "Tatooine",
                    climate: "Arid",
                    gravity: "1",
                    terrain: "Desert",
                    diameter: "10465",
                    population: "200000"
                ),
            ]
        )
        baseService.firstPage = page

        // When: ingesting first page (wait for indexing to finish)
        let expectationIngest = expectation(description: "ingest")
        decorator.fetchFirstPage()
            .sink(
                receiveCompletion: { _ in
                    indexQueue.sync {}
                    expectationIngest.fulfill()
                },
                receiveValue: { _ in }
            )
            .store(in: &subscriptions)
        wait(for: [expectationIngest], timeout: 1.0)

        // Then: queries match across name, climate, terrain; diacritics/case ignored
        assertSearch(decorator, query: "tat", expects: ["Tatooine"])
        assertSearch(decorator, query: "temperate", expects: ["Endor"])
        assertSearch(decorator, query: "tundra", expects: ["Hoth"])
        assertSearch(decorator, query: "", expects: ["Endor", "Hoth", "Tatooine"])
    }

    func testOneShotFailureHook() {
        // Given: decorator configured to fail once, then succeed
        let baseService = StubPlanetsService()
        let decorator = PlanetsSearchDecorator(base: baseService, scheduler: .main, latency: .zero)

        // When: first search triggers injected failure
        decorator.setNextSearchFailure(.message("Boom"))

        let expectationFirstFailure = expectation(description: "fails first time")
        var firstError: AppError?
        decorator.searchPlanets(query: "anything")
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion { firstError = error }
                    expectationFirstFailure.fulfill()
                },
                receiveValue: { _ in
                    XCTFail("Should not succeed on first search")
                }
            )
            .store(in: &subscriptions)
        wait(for: [expectationFirstFailure], timeout: 1.0)

        // Then: error is `.message("Boom")`; subsequent searches succeed (base default)
        guard case .message(let message)? = firstError else {
            return XCTFail("Expected .message")
        }
        XCTAssertEqual(message, "Boom")

        let expectationSecondSuccess = expectation(description: "succeeds second time")
        decorator.searchPlanets(query: "anything")
            .sink(
                receiveCompletion: { _ in expectationSecondSuccess.fulfill() },
                receiveValue: { _ in }
            )
            .store(in: &subscriptions)
        wait(for: [expectationSecondSuccess], timeout: 1.0)
    }

    // MARK: - Helpers

    private func assertSearch(
        _ decorator: PlanetsSearchDecorator,
        query: String,
        expects names: [String],
        file: StaticString = #file,
        line: UInt = #line
    ) {
        // Given: a prepared decorator index; When: searchPlanets(query:) is called; Then: names match set-wise
        let expectationSearch = expectation(description: "search \(query)")
        var results: [Planet] = []

        decorator.searchPlanets(query: query)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { page in
                    results = page.planets
                    expectationSearch.fulfill()
                }
            )
            .store(in: &subscriptions)

        wait(for: [expectationSearch], timeout: 1.0)

        XCTAssertEqual(Set(results.map(\.name)), Set(names), file: file, line: line)
    }

    func testLatencyHonored() {
        // Given: decorator with 10ms artificial latency and a page to ingest
        let baseService = StubPlanetsService()
        baseService.firstPage = PlanetsPage(
            next: nil,
            planets: [Planet(name: "Dagobah", climate: "", gravity: "", terrain: "", diameter: "", population: "")]
        )
        let decorator = PlanetsSearchDecorator(base: baseService, scheduler: .main, latency: .milliseconds(10))

        // When: fetch then search; measure elapsed time
        let expectationLatencyRespected = expectation(description: "latency respected")
        let startTime = Date()
        decorator.fetchFirstPage()
            .flatMap { _ in decorator.searchPlanets(query: "") }
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { _ in
                    let elapsed = Date().timeIntervalSince(startTime)
                    // Then: elapsed time is ≥ configured latency
                    XCTAssertGreaterThanOrEqual(elapsed, 0.01)
                    expectationLatencyRespected.fulfill()
                }
            )
            .store(in: &subscriptions)
        wait(for: [expectationLatencyRespected], timeout: 1.0)
    }
}
