// Path: StarWarsTests/TestSupport/Utilities/DataLoader.swift
// Role: Load fixture JSON files for decoding tests

// Given: a fixture name expected in the test bundle
// When: loadJSON(named:) is called
// Then: returns its Data or throws descriptive "Fixture <name>.json not found"

import Foundation

enum DataLoader {
    static func loadJSON(named name: String) throws -> Data {
        let bundle = Bundle(for: DummyClass.self)
        guard let url = bundle.url(forResource: name, withExtension: "json") else {
            throw NSError(
                domain: "Fixture",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Fixture \(name).json not found"]
            )
        }
        return try Data(contentsOf: url)
    }

    private final class DummyClass {}
}
