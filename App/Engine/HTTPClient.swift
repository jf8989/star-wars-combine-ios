// App/Engine/HTTPClient.swift

import Combine
import Foundation

/// Minimal HTTP client abstraction for Combine-based requests.
public protocol HTTPClient {
    func get(url: URL, headers: [String: String]) -> AnyPublisher<
        Data, URLError
    >
}

extension HTTPClient {
    public func get(url: URL) -> AnyPublisher<Data, URLError> {
        get(url: url, headers: [:])
    }
}

/// URLSession-based implementation.
/// Note: Request/response decoding is handled in services; this only returns Data.
public struct URLSessionHTTPClient: HTTPClient {
    private let session: URLSession

    public init(configuration: URLSessionConfiguration = .default) {
        self.session = URLSession(configuration: configuration)
    }

    public func get(url: URL, headers: [String: String] = [:]) -> AnyPublisher<
        Data, URLError
    > {
        var request = URLRequest(url: url)
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        return session.dataTaskPublisher(for: request)
            .map(\.data)
            .eraseToAnyPublisher()
    }
}
