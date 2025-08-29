// Model/Planet.swift

import Foundation

/// Minimal domain model used by ViewModel & View.
/// Keep strings as delivered; presentation formatting happens at the UI layer.
public struct Planet: Equatable, Hashable {
    public let name: String
    public let climate: String
    public let gravity: String
    public let terrain: String
    public let diameter: String
    public let population: String

    public init(
        name: String,
        climate: String,
        gravity: String,
        terrain: String,
        diameter: String,
        population: String
    ) {
        self.name = name
        self.climate = climate
        self.gravity = gravity
        self.terrain = terrain
        self.diameter = diameter
        self.population = population
    }
}
