/// Path: StarWarsTests/ViewModels/Planets/PlanetsViewModelTests_Search.swift
/// Role: Search-mode behavior (query, debounce, restore)

import Combine
import XCTest

@testable import StarWarsCombine

final class PlanetsViewModelSearchTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []

    // MARK: - Lifecycle
    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    // MARK: - Search Mode

    func testSearchSwitchesModeAndRestoresOnClear() {
        // Given: two planets (Endor, Hoth); search results scripted for Hoth
        let stubService = StubPlanetsService()
        stubService.firstPage = PlanetsPage(
            next: nil,
            planets: [
                Planet(name: "Endor", climate: "", gravity: "", terrain: "", diameter: "", population: ""),
                Planet(name: "Hoth", climate: "", gravity: "", terrain: "", diameter: "", population: ""),
            ]
        )
        stubService.searchResults = PlanetsPage(
            next: nil,
            planets: [Planet(name: "Hoth", climate: "", gravity: "", terrain: "", diameter: "", population: "")]
        )

        let viewModel = PlanetsViewModel(service: stubService, debounceInterval: 0.2)

        // When: searchTerm set to "Hoth", then cleared
        let expectSearchResults = expectation(description: "search results emitted")
        let expectRestoreAfterClear = expectation(description: "restore after clearing search")

        viewModel.$displayPlanets
            .sink { planets in
                let planetNames = planets.map(\.name)
                // Then: emission shows only Hoth, then later restores both
                if planetNames == ["Hoth"] { expectSearchResults.fulfill() }
                if Set(planetNames) == Set(["Endor", "Hoth"]) { expectRestoreAfterClear.fulfill() }
            }
            .store(in: &cancellables)

        let expectFirstPageVisible = expectation(description: "first page visible")
        viewModel.$displayPlanets
            .drop(while: { $0.isEmpty })
            .prefix(1)
            .sink { _ in expectFirstPageVisible.fulfill() }
            .store(in: &cancellables)

        viewModel.loadFirstPage()
        wait(for: [expectFirstPageVisible], timeout: 1.0)

        viewModel.searchTerm = "Hoth"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { viewModel.searchTerm = "" }

        wait(for: [expectSearchResults, expectRestoreAfterClear], timeout: 2.0)
    }

    func testSearchFailureMapsToAlert() {
        // Given: stub configured with error
        let stubService = StubPlanetsService()
        stubService.error = .message("Boom")
        let viewModel = PlanetsViewModel(service: stubService, debounceInterval: 0.01)

        // When: searchTerm set
        let expectAlertSet = expectation(description: "alert set after search debounce")
        viewModel.$alert
            .dropFirst()
            .prefix(1)
            .sink { message in
                // Then: alert message is propagated
                XCTAssertEqual(message, "Boom")
                expectAlertSet.fulfill()
            }
            .store(in: &cancellables)

        viewModel.searchTerm = "query"
        wait(for: [expectAlertSet], timeout: 1.0)
    }
}
