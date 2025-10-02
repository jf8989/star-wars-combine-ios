/// Path: StarWarsTestsPlanetsScreen/PlanetsSortingTests.swift
/// Role: Presentation sort policy tests

import XCTest

@testable import StarWarsCombine

final class PlanetsSortingTests: XCTestCase {

    func testAlphaSort_IsCaseAndDiacriticInsensitive() {
        // Given: an unsorted list with mixed case and diacritics
        let unsorted = [
            Planet(
                name: "éndor",
                climate: "mild",
                gravity: "1",
                terrain: "forest",
                diameter: "4900",
                population: "30000"
            ),
            Planet(
                name: "Alderaan",
                climate: "temperate",
                gravity: "1",
                terrain: "grasslands",
                diameter: "12500",
                population: "2000000000"
            ),
            Planet(
                name: "tatooine",
                climate: "arid",
                gravity: "1",
                terrain: "desert",
                diameter: "10465",
                population: "200000"
            ),
        ]

        // When: applying presentation alpha sort
        let sorted = PlanetsSorting.alpha(unsorted).map { $0.name }

        // Then: order matches case/diacritic-insensitive compare (Alderaan, Endor, Tatooine)
        XCTAssertEqual(
            sorted,
            ["Alderaan", "éndor", "tatooine"].sorted {
                $0.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
                    < $1.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            }
        )
    }

    func testAlphaSort_StableWithAlreadySortedInput() {
        // Given: already sorted input by name
        let sortedInput = [
            Planet(name: "Alderaan", climate: "", gravity: "", terrain: "", diameter: "", population: ""),
            Planet(name: "Bespin", climate: "", gravity: "", terrain: "", diameter: "", population: ""),
            Planet(name: "Crait", climate: "", gravity: "", terrain: "", diameter: "", population: ""),
        ]

        // When: applying alpha sort again
        let output = PlanetsSorting.alpha(sortedInput)

        // Then: order remains unchanged (stable for equal-keys)
        XCTAssertEqual(output.map { $0.name }, ["Alderaan", "Bespin", "Crait"])
    }
}
