// File: /Engine/PlanetsService.swift

import Combine
import Foundation

/// Service abstraction for fetching SWAPI planets.
public protocol PlanetsService {
    /// Fetch first page of planets.
    func fetchFirstPage() -> AnyPublisher<PlanetsPageDTO, Error>
    /// Fetch next page using absolute URL from previous response.
    func fetchPage(at url: URL) -> AnyPublisher<PlanetsPageDTO, Error>
}

/// Lightweight DTOs to keep Phase 0 compiling; real mapping lands in Phase 2.
public struct PlanetsPageDTO: Decodable {
    public let next: URL?
    public let results: [PlanetDTO]
}

public struct PlanetDTO: Decodable {
    public let name: String
    public let climate: String
    public let gravity: String
    public let terrain: String
    public let diameter: String
    public let population: String
}
