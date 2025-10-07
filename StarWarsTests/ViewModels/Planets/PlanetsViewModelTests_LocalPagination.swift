/// Path: StarWarsTests/ViewModels/Planets/PlanetsViewModelTests_LocalPagination.swift
/// Role: Client-side pagination (slicing) behavior

import Combine
import XCTest

@testable import StarWarsCombine

final class PlanetsViewModelLocalPaginationTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []

    // MARK: - Lifecycle
    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    // MARK: - Local Pagination (client-side slices)

    func testGoNextPage_UsesLocalSliceAfterAlphaSort() {
        // Given: 20 alphabetic names A…T; page size is 10 → two slices
        let stubService = StubPlanetsService()
        stubService.firstPage = PlanetsPage(next: nil, planets: makeAlphabetPlanets(20))
        let viewModel = PlanetsViewModel(service: stubService)

        // When: load first page, then call goNextPage()
        let expectDisplaySequenceSlices = trackDisplay(
            from: viewModel,
            cancellables: &cancellables,
            fulfillOn: 3
        ) { emissionStep, planetNames in
            // Then: second emission A…J, third emission K…T
            switch emissionStep {
            case 2:
                XCTAssertEqual(planetNames.first, "A")
                XCTAssertEqual(planetNames.last, "J")
            case 3:
                XCTAssertEqual(planetNames.first, "K")
                XCTAssertEqual(planetNames.last, "T")
            default: break
            }
        }

        viewModel.loadFirstPage()
        DispatchQueue.main.async { viewModel.goNextPage() }

        wait(for: [expectDisplaySequenceSlices], timeout: 1.0)
        XCTAssertEqual(viewModel.currentPageDisplay, 2)
    }

    func testGoPrevPage_RespectsLowerBound() {
        // Given: 15 items → pages of 10 + 5
        let stubService = StubPlanetsService()
        stubService.firstPage = PlanetsPage(next: nil, planets: makeAlphabetPlanets(15))
        let viewModel = PlanetsViewModel(service: stubService)

        // When: advance to page 2, then goPrevPage()
        let expectCycleAcrossPages = trackDisplay(
            from: viewModel,
            cancellables: &cancellables,
            fulfillOn: 4
        ) { emissionStep, planetNames in
            // Then: emissions cycle A…J → K…O → back to A…J
            if emissionStep == 2 { XCTAssertEqual(planetNames.first, "A") }
            if emissionStep == 3 { XCTAssertEqual(planetNames.first, "K") }
            if emissionStep == 4 { XCTAssertEqual(planetNames.first, "A") }
        }

        viewModel.loadFirstPage()
        DispatchQueue.main.async {
            viewModel.goNextPage()
            viewModel.goPrevPage()
        }

        wait(for: [expectCycleAcrossPages], timeout: 1.0)
        XCTAssertEqual(viewModel.currentPageDisplay, 1)
    }
}
