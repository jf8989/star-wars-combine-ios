// File: /Engine/PlanetsServiceImpl.swift

import Combine
import Foundation

public final class PlanetsServiceImpl: PlanetsService {
    private let http: HTTPClient
    private let decoder: JSONDecoder
    private let base: URL

    public init(
        http: HTTPClient,
        base: URL = URL(string: "https://swapi.dev/api")!,
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
            .tryMap { [decoder] data in
                try decoder.decode(PlanetsPageDTO.self, from: data)
            }
            .map { dto -> PlanetsPage in
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
            .mapError { error -> AppError in
                if let e = error as? URLError { return .network(e) }
                return .decode(error)
            }
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
