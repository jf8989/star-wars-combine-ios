// Path: StarWarsCombineTests/PlanetTests.swift
import XCTest

@testable import StarWarsCombine

final class PlanetTests: XCTestCase {
    func testLoadFixture() throws {
        let data = try DataLoader.loadJSON(named: "planet_single")
        XCTAssertFalse(data.isEmpty, "Fixture should load and not be empty")
    }
}
