/// Path: StarWarsTests/ViewModels/Planets/PlanetsViewModelTests_ServerPagination.swift
/// Role: Server-driven paging (next-page URL) behavior

import Combine
import XCTest

@testable import StarWarsCombine

final class PlanetsViewModelServerPaginationTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []

    // MARK: - Lifecycle
    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    // MARK: - Server Pagination (API-driven)

    func testServerPagingDisplaysUnknownTotal() {
        // Given: firstPage has "next" URL → implies server paging
        let stubService = StubPlanetsService()
        stubService.firstPage = PlanetsPage(
            next: URL(string: "https://next"),
            planets: [Planet(name: "A", climate: "", gravity: "", terrain: "", diameter: "", population: "")]
        )
        let viewModel = PlanetsViewModel(service: stubService, debounceInterval: .zero)

        // When: loadFirstPage
        let expectFirstPageLoaded = expectation(description: "first page loaded")
        viewModel.$displayPlanets
            .dropFirst()
            .prefix(1)
            .sink { _ in expectFirstPageLoaded.fulfill() }
            .store(in: &cancellables)
        viewModel.loadFirstPage()
        wait(for: [expectFirstPageLoaded], timeout: 1.0)

        // Then: totalPages unknown, canLoadMore true
        XCTAssertEqual(viewModel.totalPagesDisplay, "?")
        XCTAssertTrue(viewModel.canLoadMore)
    }

    func testGoNextPageFetchesFromServer() {
        // Given: firstPage with next URL, and nextPage scripted
        let stubService = StubPlanetsService()
        stubService.firstPage = PlanetsPage(
            next: URL(string: "https://next"),
            planets: [Planet(name: "A", climate: "", gravity: "", terrain: "", diameter: "", population: "")]
        )
        stubService.nextPage = PlanetsPage(
            next: nil,
            planets: [Planet(name: "B", climate: "", gravity: "", terrain: "", diameter: "", population: "")]
        )

        let viewModel = PlanetsViewModel(service: stubService, debounceInterval: .zero)

        // When: load then goNextPage()
        let expectSecondPageMerged = expectation(description: "second page merged")
        viewModel.$displayPlanets
            .sink { planets in
                // Then: emission eventually contains B
                if planets.map(\.name).contains("B") { expectSecondPageMerged.fulfill() }
            }
            .store(in: &cancellables)

        viewModel.loadFirstPage()
        DispatchQueue.main.async { viewModel.goNextPage() }

        wait(for: [expectSecondPageMerged], timeout: 1.0)
        XCTAssertEqual(viewModel.pageDirection, .forward)
    }
}
