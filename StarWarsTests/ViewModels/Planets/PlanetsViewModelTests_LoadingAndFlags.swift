/// Path: StarWarsTests/ViewModels/Planets/PlanetsViewModelTests_LoadingAndFlags.swift
/// Role: Loading flow and derived flags/counters

import Combine
import XCTest

@testable import StarWarsCombine

final class PlanetsViewModelLoadingAndFlagsTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []

    // MARK: - Lifecycle
    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    // MARK: - Loading & Initial Display

    func testLoadFirstPageDisplaysPlanets() {
        // Given: Stub service with first page containing Tatooine
        let stubService = StubPlanetsService()
        stubService.firstPage = PlanetsPage(
            next: nil,
            planets: [
                Planet(
                    name: "Tatooine",
                    climate: "arid",
                    gravity: "1",
                    terrain: "desert",
                    diameter: "10465",
                    population: "200000"
                )
            ]
        )
        let viewModel = PlanetsViewModel(service: stubService)

        // When: loadFirstPage() is called
        let expectFirstNonEmptyDisplay = expectation(description: "loaded first page")
        viewModel.$displayPlanets
            .drop(while: { $0.isEmpty })
            .prefix(1)
            .sink { planets in
                // Then: first non-empty emission shows Tatooine
                XCTAssertEqual(planets.first?.name, "Tatooine")
                expectFirstNonEmptyDisplay.fulfill()
            }
            .store(in: &cancellables)

        viewModel.loadFirstPage()
        wait(for: [expectFirstNonEmptyDisplay], timeout: 1.0)
    }

    func testDerivedFlagsReflectState_AfterLoadCompletes() {
        // Given: 12 items → 2 pages
        let stubService = StubPlanetsService()
        stubService.firstPage = PlanetsPage(next: nil, planets: makeAlphabetPlanets(12))
        let viewModel = PlanetsViewModel(service: stubService)

        // When: loadFirstPage completes
        let expectFirstPageVisible = expectation(description: "first page visible")
        viewModel.$displayPlanets
            .drop(while: { $0.isEmpty })
            .prefix(1)
            .sink { _ in expectFirstPageVisible.fulfill() }
            .store(in: &cancellables)

        viewModel.loadFirstPage()
        wait(for: [expectFirstPageVisible], timeout: 1.0)

        // Then: flags and counters updated
        XCTAssertTrue(viewModel.canLoadMore)
        XCTAssertEqual(viewModel.currentPageDisplay, 1)
        XCTAssertEqual(viewModel.totalPagesDisplay, "2")
    }

    func testCanLoadMore_IsFalseWhileLoading() {
        // Given: firstPage with content, so loadFirstPage triggers loading state
        let stubService = StubPlanetsService()
        stubService.firstPage = PlanetsPage(
            next: nil,
            planets: [Planet(name: "A", climate: "", gravity: "", terrain: "", diameter: "", population: "")]
        )
        let viewModel = PlanetsViewModel(service: stubService, debounceInterval: .zero)

        // When: loadFirstPage triggered
        viewModel.loadFirstPage()

        // Then: canLoadMore should be false during load
        XCTAssertFalse(viewModel.canLoadMore)
    }
}
