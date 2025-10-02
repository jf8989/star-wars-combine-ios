/// Path: StarWarsTests/ViewModels/PlanetsViewModelTests.swift
/// Role: Deterministic behavior tests for PlanetsViewModel (paging + search)

import Combine
import XCTest

@testable import StarWarsCombine

final class PlanetsViewModelTests: XCTestCase {

    private var cancellables: Set<AnyCancellable> = []

    // MARK: - Helpers

    /// Subscribes to `displayPlanets` and advances a step counter on each emission.
    private func trackDisplay(
        from viewModel: PlanetsViewModel,
        fulfillOn stepToFulfill: Int,
        _ onStep: @escaping (_ step: Int, _ names: [String]) -> Void
    ) -> XCTestExpectation {
        let expectation = expectation(description: "displayPlanets emitted step \(stepToFulfill)")
        var step = 0
        viewModel.$displayPlanets
            .sink { planets in
                step += 1
                onStep(step, planets.map(\.name))
                if step == stepToFulfill { expectation.fulfill() }
            }
            .store(in: &cancellables)
        return expectation
    }

    private func makeAlphabetPlanets(_ count: Int) -> [Planet] {
        let letters = (0..<count).map { index -> String in
            let scalar = UnicodeScalar(65 + (index % 26))!  // A, B, C…
            return String(Character(scalar))
        }
        return letters.map { Planet(name: $0, climate: "", gravity: "", terrain: "", diameter: "", population: "") }
    }

    // MARK: - Tests

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
        let expectation = expectation(description: "loaded first page")
        viewModel.$displayPlanets
            .drop(while: { $0.isEmpty })
            .prefix(1)
            .sink { planets in
                // Then: first non-empty emission shows Tatooine
                XCTAssertEqual(planets.first?.name, "Tatooine")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        viewModel.loadFirstPage()

        wait(for: [expectation], timeout: 1.0)
    }

    func testGoNextPage_UsesLocalSliceAfterAlphaSort() {
        // Given: 20 alphabetic names A…T; page size is 10 → two slices
        let stubService = StubPlanetsService()
        stubService.firstPage = PlanetsPage(next: nil, planets: makeAlphabetPlanets(20))
        let viewModel = PlanetsViewModel(service: stubService)

        // When: load first page, then call goNextPage()
        let expectation = trackDisplay(from: viewModel, fulfillOn: 3) { step, names in
            // Then: second emission A…J, third emission K…T
            switch step {
            case 2:
                XCTAssertEqual(names.first, "A")
                XCTAssertEqual(names.last, "J")
            case 3:
                XCTAssertEqual(names.first, "K")
                XCTAssertEqual(names.last, "T")
            default: break
            }
        }

        viewModel.loadFirstPage()
        DispatchQueue.main.async { viewModel.goNextPage() }

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(viewModel.currentPageDisplay, 2)
    }

    func testGoPrevPage_RespectsLowerBound() {
        // Given: 15 items → pages of 10 + 5
        let stubService = StubPlanetsService()
        stubService.firstPage = PlanetsPage(next: nil, planets: makeAlphabetPlanets(15))
        let viewModel = PlanetsViewModel(service: stubService)

        // When: advance to page 2, then goPrevPage()
        let expectation = trackDisplay(from: viewModel, fulfillOn: 4) { step, names in
            // Then: emissions cycle A…J → K…O → back to A…J
            if step == 2 { XCTAssertEqual(names.first, "A") }
            if step == 3 { XCTAssertEqual(names.first, "K") }
            if step == 4 { XCTAssertEqual(names.first, "A") }
        }

        viewModel.loadFirstPage()
        DispatchQueue.main.async {
            viewModel.goNextPage()
            viewModel.goPrevPage()
        }

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(viewModel.currentPageDisplay, 1)
    }

    func testDerivedFlagsReflectState_AfterLoadCompletes() {
        // Given: 12 items → 2 pages
        let stubService = StubPlanetsService()
        stubService.firstPage = PlanetsPage(next: nil, planets: makeAlphabetPlanets(12))
        let viewModel = PlanetsViewModel(service: stubService)

        // When: loadFirstPage completes
        let expectation = expectation(description: "first page visible")
        viewModel.$displayPlanets.drop(while: { $0.isEmpty }).prefix(1).sink { _ in expectation.fulfill() }.store(
            in: &cancellables
        )

        viewModel.loadFirstPage()
        wait(for: [expectation], timeout: 1.0)

        // Then: flags and counters updated
        XCTAssertTrue(viewModel.canLoadMore)
        XCTAssertEqual(viewModel.currentPageDisplay, 1)
        XCTAssertEqual(viewModel.totalPagesDisplay, "2")
    }

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

        let viewModel = PlanetsViewModel(service: stubService)

        // When: searchTerm set to "Hoth", then cleared
        let expectationSearch = expectation(description: "search results emitted")
        let expectationRestore = expectation(description: "restore after clearing search")

        viewModel.$displayPlanets
            .sink { names in
                let justNames = names.map(\.name)
                // Then: emission shows only Hoth, then later restores both
                if justNames == ["Hoth"] { expectationSearch.fulfill() }
                if Set(justNames) == Set(["Endor", "Hoth"]) { expectationRestore.fulfill() }
            }
            .store(in: &cancellables)

        let expectationFirstPage = expectation(description: "first page visible")
        viewModel.$displayPlanets.drop(while: { $0.isEmpty }).prefix(1).sink { _ in expectationFirstPage.fulfill() }
            .store(
                in: &cancellables
            )

        viewModel.loadFirstPage()
        wait(for: [expectationFirstPage], timeout: 1.0)

        viewModel.searchTerm = "Hoth"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { viewModel.searchTerm = "" }

        wait(for: [expectationSearch, expectationRestore], timeout: 2.0)
    }

    func testSearchFailureMapsToAlert() {
        // Given: stub configured with error
        let stubService = StubPlanetsService()
        stubService.error = .message("Boom")
        let viewModel = PlanetsViewModel(service: stubService)

        // When: searchTerm set
        let expectation = expectation(description: "alert set after search debounce")
        viewModel.$alert.dropFirst().prefix(1).sink { message in
            // Then: alert message is propagated
            XCTAssertEqual(message, "Boom")
            expectation.fulfill()
        }.store(in: &cancellables)

        viewModel.searchTerm = "query"
        wait(for: [expectation], timeout: 1.0)
    }

    func testServerPagingDisplaysUnknownTotal() {
        // Given: firstPage has "next" URL → implies server paging
        let stubService = StubPlanetsService()
        stubService.firstPage = PlanetsPage(
            next: URL(string: "https://next"),
            planets: [Planet(name: "A", climate: "", gravity: "", terrain: "", diameter: "", population: "")]
        )
        let viewModel = PlanetsViewModel(service: stubService, debounceInterval: .zero)

        // When: loadFirstPage
        let expectation = expectation(description: "first page loaded")
        viewModel.$displayPlanets.dropFirst().prefix(1).sink { _ in expectation.fulfill() }.store(in: &cancellables)
        viewModel.loadFirstPage()
        wait(for: [expectation], timeout: 1.0)

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
        let expectation = expectation(description: "second page merged")
        viewModel.$displayPlanets.sink { planets in
            // Then: emission eventually contains B
            if planets.map(\.name).contains("B") { expectation.fulfill() }
        }.store(in: &cancellables)

        viewModel.loadFirstPage()
        DispatchQueue.main.async { viewModel.goNextPage() }

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(viewModel.pageDirection, .forward)
    }

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

    func testFirstPageFailureSetsAlert() {
        // Given: stub with error
        let stubService = StubPlanetsService()
        stubService.error = .message("FailFirst")
        let viewModel = PlanetsViewModel(service: stubService, debounceInterval: .zero)

        // When: loadFirstPage()
        let expectation = expectation(description: "alert set")
        viewModel.$alert.dropFirst().prefix(1).sink { message in
            // Then: alert propagated
            XCTAssertEqual(message, "FailFirst")
            expectation.fulfill()
        }.store(in: &cancellables)

        viewModel.loadFirstPage()
        wait(for: [expectation], timeout: 1.0)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testNextPageFailureSetsAlert() {
        // Given: firstPage with next + stub error on fetch
        let stubService = StubPlanetsService()
        stubService.firstPage = PlanetsPage(
            next: URL(string: "https://next"),
            planets: [Planet(name: "X", climate: "", gravity: "", terrain: "", diameter: "", population: "")]
        )
        stubService.error = .message("FailNext")
        let viewModel = PlanetsViewModel(service: stubService, debounceInterval: .zero)

        // When: goNextPage after load
        viewModel.loadFirstPage()
        let expectation = expectation(description: "alert after next page")
        viewModel.$alert.dropFirst().prefix(1).sink { message in
            // Then: alert propagated
            XCTAssertEqual(message, "FailNext")
            expectation.fulfill()
        }.store(in: &cancellables)

        DispatchQueue.main.async { viewModel.goNextPage() }
        wait(for: [expectation], timeout: 1.0)
        XCTAssertFalse(viewModel.isLoading)
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
