// Path: StarWarsTests/PlanetsScreen/PlanetTests.swift

import XCTest

@testable import StarWarsCombine

final class PlanetTests: XCTestCase {
    func testLoadFixture() throws {
        // Given: a known JSON fixture named "planet_single" in the test bundle
        // When: DataLoader.loadJSON(named:) is called
        // Then: returned Data is non-empty (fixture file exists and loads)
        let data = try DataLoader.loadJSON(named: "planet_single")
        XCTAssertFalse(data.isEmpty, "Fixture should load and not be empty")
    }
}
