/// Path: StarWarsTests/ViewModels/Planets/PlanetsViewModelTests_ErrorsAndAlerts.swift
/// Role: Error propagation to user-facing alerts

import Combine
import XCTest

@testable import StarWarsCombine

final class PlanetsViewModelErrorsAndAlertsTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []

    // MARK: - Lifecycle
    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    // MARK: - Errors & Alerts

    func testFirstPageFailureSetsAlert() {
        // Given: stub with error
        let stubService = StubPlanetsService()
        stubService.error = .message("FailFirst")
        let viewModel = PlanetsViewModel(service: stubService, debounceInterval: .zero)

        // When: loadFirstPage()
        let expectAlertAfterFirstPage = expectation(description: "alert set")
        viewModel.$alert
            .dropFirst()
            .prefix(1)
            .sink { message in
                // Then: alert propagated
                XCTAssertEqual(message, "FailFirst")
                expectAlertAfterFirstPage.fulfill()
            }
            .store(in: &cancellables)

        viewModel.loadFirstPage()
        wait(for: [expectAlertAfterFirstPage], timeout: 1.0)
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
        let expectAlertAfterNextPage = expectation(description: "alert after next page")
        viewModel.$alert
            .dropFirst()
            .prefix(1)
            .sink { message in
                // Then: alert propagated
                XCTAssertEqual(message, "FailNext")
                expectAlertAfterNextPage.fulfill()
            }
            .store(in: &cancellables)

        DispatchQueue.main.async { viewModel.goNextPage() }
        wait(for: [expectAlertAfterNextPage], timeout: 1.0)
        XCTAssertFalse(viewModel.isLoading)
    }
}
