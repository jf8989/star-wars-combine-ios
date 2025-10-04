/// Path: StarWarsTests/TestSupport/Networking/StubURLProtocol.swift
/// Role: Deterministic transport stub for URLSession; captures requests and simulates success/failure

import Foundation

final class StubURLProtocol: URLProtocol {
    enum Mode {
        case success(data: Data)
        case failure(error: URLError)
    }

    static var mode: Mode = .success(data: Data())
    static var capturedRequests: [URLRequest] = []

    static func reset() {
        mode = .success(data: Data())
        capturedRequests = []
    }

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        // Given: request captured and mode configured
        Self.capturedRequests.append(request)

        switch Self.mode {
        case .success(let data):
            // When: succeeding with 200 + data
            guard let url = request.url else {
                client?.urlProtocol(self, didFailWithError: URLError(.badURL))
                return
            }
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: [:])!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)

        case .failure(let error):
            // Then: propagate configured URLError
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() { /* no-op */  }
}
