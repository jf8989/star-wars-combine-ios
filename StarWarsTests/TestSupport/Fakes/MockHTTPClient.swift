// Path: StarWarsTests/TestSupport/Fakes/MockHTTPClient.swift
// Role: Fake HTTP client to simulate requests

// Given: tests configure `response` and observe `requestedURLs`
// When: `get(url:headers:)` is called by code under test
// Then: a publisher emits the scripted `Data` or fails with the scripted `URLError`
//       (or completes empty if `response == nil`) — no real network used

import Combine
import Foundation

@testable import StarWarsCombine

final class MockHTTPClient: HTTPClient {
    enum Response {
        case success(Data)
        case failure(URLError)
    }

    private(set) var requestedURLs: [URL] = []
    var response: Response?

    // Given: an optional scripted `response`
    // When: `get(url:headers:)` is invoked
    // Then: record the URL; emit `Just(data)` on success, `Fail` on failure, or `Empty` if unset
    func get(url: URL, headers: [String: String] = [:]) -> AnyPublisher<Data, URLError> {
        requestedURLs.append(url)
        switch response {
        case .success(let data):
            return Just(data)
                .setFailureType(to: URLError.self)
                .eraseToAnyPublisher()
        case .failure(let error):
            return Fail(error: error).eraseToAnyPublisher()
        case .none:
            return Empty().eraseToAnyPublisher()
        }
    }
}
