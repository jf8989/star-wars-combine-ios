/// Path: StarWarsTests/TestSupport/Fakes/MockHTTPClient.swift
/// Role: Fake HTTP client to simulate requests

// Given: tests configure `response` and observe `requestedURLs`
// When: `get(url:headers:)` is called by code under test
// Then: a publisher emits the scripted `Data` or fails with the scripted `URLError`
//       (or completes empty if `response == nil`) — no real network used

import Combine
import Foundation

@testable import StarWarsCombine

// MARK: - Mock

final class MockHTTPClient: HTTPClient {

    // MARK: Scripted response

    enum Response {
        case success(Data)
        case failure(URLError)
    }

    var response: Response?

    // MARK: Observability

    private(set) var requestedURLs: [URL] = []
    private(set) var requestedHeadersHistory: [[String: String]] = []

    // MARK: Lifecycle

    /// Clears all recorded requests and scripted response.
    func reset() {
        requestedURLs = []
        requestedHeadersHistory = []
        response = nil
    }

    // MARK: Convenience (optional sugar)

    func setSuccess(data: Data) { response = .success(data) }
    func setFailure(error: URLError) { response = .failure(error) }

    // MARK: HTTPClient

    // Given: an optional scripted `response`
    // When: `get(url:headers:)` is invoked
    // Then: record the URL and headers; emit `Just(data)` on success, `Fail` on failure, or `Empty` if unset
    func get(url: URL, headers: [String: String] = [:]) -> AnyPublisher<Data, URLError> {
        requestedURLs.append(url)
        requestedHeadersHistory.append(headers)

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
