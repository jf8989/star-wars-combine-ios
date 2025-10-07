/// Path: StarWarsTests/TestSupport/Utilities/DataLoader.swift
/// Role: Load fixture JSON files for decoding tests

// Given: a fixture name expected in the test bundle
// When: loadJSON(named:) is called
// Then: returns its Data or throws descriptive "Fixture <name>.json not found"

import Foundation

enum DataLoader {

    enum DataLoaderError: LocalizedError {
        case fixtureNotFound(name: String)

        var errorDescription: String? {
            switch self {
            case .fixtureNotFound(let name):
                return "Fixture \(name).json not found"
            }
        }
    }

    static func loadJSON(named name: String) throws -> Data {
        let bundle = Bundle(for: TestBundleToken.self)
        guard let url = bundle.url(forResource: name, withExtension: "json") else {
            throw DataLoaderError.fixtureNotFound(name: name)
        }
        return try Data(contentsOf: url)
    }

    /// Empty class used only to retrieve the unit test bundle.
    private final class TestBundleToken {}
}
