// StarWarsCombine/Services/PlanetsServiceLive.swift

import Combine
import Foundation

public final class PlanetsServiceLive: PlanetsService {
    private let http: HTTPClient
    private let decoder: JSONDecoder
    private let base: URL

    public init(
        http: HTTPClient,
        base: URL = URL(string: "https://swapi.info/api")!,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.http = http
        self.base = base
        self.decoder = decoder
    }

    func fetchFirstPage() -> AnyPublisher<PlanetsPage, AppError> {
        let url = makeURL(path: "/planets/")
        return pagePublisher(for: url)
    }

    func fetchPage(at url: URL) -> AnyPublisher<PlanetsPage, AppError> {
        pagePublisher(for: url)
    }

    func searchPlanets(query: String) -> AnyPublisher<
        PlanetsPage, AppError
    > {
        let url = makeURL(
            path: "/planets/",
            query: [URLQueryItem(name: "search", value: query)]
        )
        return pagePublisher(for: url)
    }

    // MARK: - Helpers

    private func pagePublisher(for url: URL) -> AnyPublisher<
        PlanetsPage, AppError
    > {
        http.get(url: url)
            .tryMap { [decoder] data -> PlanetsPage in
                // 1) Try swapi.dev shape: { count, next, previous, results: [PlanetDTO] }
                if let pageDTO = try? decoder.decode(
                    PlanetsPageDTO.self,
                    from: data
                ) {
                    let planets = pageDTO.results.map {
                        Planet(
                            name: $0.name,
                            climate: $0.climate,
                            gravity: $0.gravity,
                            terrain: $0.terrain,
                            diameter: $0.diameter,
                            population: $0.population
                        )
                    }
                    let nextURL = pageDTO.next.flatMap(URL.init(string:))
                    return PlanetsPage(next: nextURL, planets: planets)
                }

                // 2) Try swapi.info shape: raw array [PlanetDTO]
                if let planetDTOs = try? decoder.decode(
                    [PlanetDTO].self,
                    from: data
                ) {
                    let planets = planetDTOs.map {
                        Planet(
                            name: $0.name,
                            climate: $0.climate,
                            gravity: $0.gravity,
                            terrain: $0.terrain,
                            diameter: $0.diameter,
                            population: $0.population
                        )
                    }
                    return PlanetsPage(next: nil, planets: planets)
                }

                // 3) Defensive: single planet payload (rare, but harmless)
                if let planetDTO = try? decoder.decode(
                    PlanetDTO.self,
                    from: data
                ) {
                    let p = Planet(
                        name: planetDTO.name,
                        climate: planetDTO.climate,
                        gravity: planetDTO.gravity,
                        terrain: planetDTO.terrain,
                        diameter: planetDTO.diameter,
                        population: planetDTO.population
                    )
                    return PlanetsPage(next: nil, planets: [p])
                }

                /// 4) If none matched, throw a descriptive error
                struct UnexpectedPayload: Error {}
                throw UnexpectedPayload()
            }
            .mapError { error -> AppError in
                if let e = error as? URLError { return .network(e) }
                return .message(
                    "Decode failed (shape mismatch). See console for payload snippet."
                )
            }
            .handleEvents(
                receiveOutput: { _ in
                    // noop
                },
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        // Help during development: show a short marker so we know which branch failed
                        print("🔎 Planets decode failed:", error)
                    }
                }
            )
            .eraseToAnyPublisher()
    }

    private func makeURL(path: String, query: [URLQueryItem]? = nil) -> URL {
        var comps = URLComponents(url: base, resolvingAgainstBaseURL: false)!
        comps.path = base.path + path
        comps.queryItems = query
        // We force unwrap here because inputs are constant; safer handling not needed for the assignment scope.
        return comps.url!
    }
}
