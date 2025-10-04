/// Path: StarWarsTests/TestSupport/Planets/PlanetsVMTestHelpers.swift
/// Role: Shared helpers for PlanetsViewModel tests (display tracking + alphabet planets)

import Combine
import XCTest

@testable import StarWarsCombine

/// Subscribes to `displayPlanets` and advances a step counter on each emission.
func trackDisplay(
    from viewModel: PlanetsViewModel,
    cancellables: inout Set<AnyCancellable>,
    fulfillOn stepToFulfill: Int,
    _ onStep: @escaping (_ emissionStep: Int, _ planetNames: [String]) -> Void
) -> XCTestExpectation {
    let expectDisplayEmitsStepN = XCTestExpectation(description: "displayPlanets emitted step \(stepToFulfill)")
    var emissionStep = 0
    viewModel.$displayPlanets
        .sink { planets in
            emissionStep += 1
            onStep(emissionStep, planets.map(\.name))
            if emissionStep == stepToFulfill { expectDisplayEmitsStepN.fulfill() }
        }
        .store(in: &cancellables)
    return expectDisplayEmitsStepN
}

/// Builds an array of planets named A, B, C… up to `count`.
func makeAlphabetPlanets(_ count: Int) -> [Planet] {
    let asciiValueOfCapitalA: UInt32 = 65  // A, B, C…
    let letters = (0..<count).map { index -> String in
        let scalar = UnicodeScalar(asciiValueOfCapitalA + UInt32(index % 26))!
        return String(Character(scalar))
    }
    return letters.map { Planet(name: $0, climate: "", gravity: "", terrain: "", diameter: "", population: "") }
}
