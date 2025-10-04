/// Path: StarWarsTests/PlanetsScreen/PlanetTests.swift
/// Role: Fixture loading and decoding checks for Planet

import Foundation
import XCTest

@testable import StarWarsCombine

final class PlanetTests: XCTestCase {

    // MARK: - Fixture existence

    func testLoadFixture_ExistsAndIsNonEmpty() throws {
        // Given: a known JSON fixture named "planet_single" in the test bundle
        // When: DataLoader.loadJSON(named:) is called
        let data = try DataLoader.loadJSON(named: "planet_single")
        // Then: returned Data is non-empty (fixture file exists and loads)
        XCTAssertFalse(data.isEmpty, "Fixture should load and not be empty")
    }

    // MARK: - Error handling

    func testLoadFixture_Missing_ThrowsFixtureNotFound() {
        // Given / When: loading a non-existent fixture
        XCTAssertThrowsError(try DataLoader.loadJSON(named: "does_not_exist")) { error in
            // Then: typed error indicates which fixture name was missing
            guard case DataLoader.DataLoaderError.fixtureNotFound(let name) = error else {
                return XCTFail("Expected DataLoaderError.fixtureNotFound, got \(error)")
            }
            XCTAssertEqual(name, "does_not_exist")
        }
    }
}
