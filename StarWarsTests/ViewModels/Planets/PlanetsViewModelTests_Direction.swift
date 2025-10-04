/// Path: StarWarsTests/ViewModels/Planets/PlanetsViewModelTests_Direction.swift
/// Role: Page direction transitions

import Combine
import XCTest

@testable import StarWarsCombine

final class PlanetsViewModelDirectionTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []

    // MARK: - Lifecycle
    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    // MARK: - Direction

    func testGoPrevPageSetsPageDirectionBackward() {
        // Given: multiple items across 2 pages
        let stubService = StubPlanetsService()
        stubService.firstPage = PlanetsPage(
            next: nil,
            planets: (1...15).map {
                Planet(name: "\($0)", climate: "", gravity: "", terrain: "", diameter: "", population: "")
            }
        )
        let viewModel = PlanetsViewModel(service: stubService, debounceInterval: .zero)

        // When: load, goNextPage, then goPrevPage
        viewModel.loadFirstPage()
        viewModel.goNextPage()
        viewModel.goPrevPage()

        // Then: pageDirection reflects backward
        XCTAssertEqual(viewModel.pageDirection, .backward)
    }
}
