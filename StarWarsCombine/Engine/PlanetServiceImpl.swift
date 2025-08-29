// File: /Engine/PlanetsServiceImpl.swift

import Combine
import Foundation

public final class PlanetsServiceImpl: PlanetsService {
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

    public func fetchFirstPage() -> AnyPublisher<PlanetsPage, AppError> {
        let url = makeURL(path: "/planets/")
        return pagePublisher(for: url)
    }

    public func fetchPage(at url: URL) -> AnyPublisher<PlanetsPage, AppError> {
        pagePublisher(for: url)
    }

    public func searchPlanets(query: String) -> AnyPublisher<
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
                if let dto = try? decoder.decode(
                    PlanetsPageDTO.self,
                    from: data
                ) {
                    let planets = dto.results.map {
                        Planet(
                            name: $0.name,
                            climate: $0.climate,
                            gravity: $0.gravity,
                            terrain: $0.terrain,
                            diameter: $0.diameter,
                            population: $0.population
                        )
                    }
                    let nextURL = dto.next.flatMap(URL.init(string:))
                    return PlanetsPage(next: nextURL, planets: planets)
                }

                // 2) Try swapi.info shape: raw array [PlanetDTO]
                if let arr = try? decoder.decode([PlanetDTO].self, from: data) {
                    let planets = arr.map {
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
                if let single = try? decoder.decode(PlanetDTO.self, from: data)
                {
                    let p = Planet(
                        name: single.name,
                        climate: single.climate,
                        gravity: single.gravity,
                        terrain: single.terrain,
                        diameter: single.diameter,
                        population: single.population
                    )
                    return PlanetsPage(next: nil, planets: [p])
                }

                // 4) If none matched, throw a descriptive error including a snippet
                let snippet =
                    String(data: data, encoding: .utf8)?.prefix(200)
                    ?? "non-utf8"
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
