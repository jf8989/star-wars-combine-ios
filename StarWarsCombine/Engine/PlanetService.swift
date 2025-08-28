// File: /Engine/PlanetsService.swift

import Combine
import Foundation

// MARK: - Domain response returned by the service
public struct PlanetsPage {
    public let next: URL?
    public let planets: [Planet]
}

// MARK: - Service Protocol
public protocol PlanetsService {
    func fetchFirstPage() -> AnyPublisher<PlanetsPage, AppError>
    func fetchPage(at url: URL) -> AnyPublisher<PlanetsPage, AppError>
    func searchPlanets(query: String) -> AnyPublisher<PlanetsPage, AppError>
}

// MARK: - Network DTOs (internal)
struct PlanetsPageDTO: Decodable {
    let next: String?  // SWAPI returns URL as String; convert to URL later
    let results: [PlanetDTO]
}

struct PlanetDTO: Decodable {
    let name: String
    let climate: String
    let gravity: String
    let terrain: String
    let diameter: String
    let population: String
}
