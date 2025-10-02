/// Path: StarWarsTests/Services/HTTPClientTests.swift
/// Role: Cover extension get(url:) forwards to headers version

import Combine
import XCTest

@testable import StarWarsCombine

final class HTTPClientTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []

    override func tearDown() {
        cancellables.removeAll()
        StubURLProtocol.reset()
        super.tearDown()
    }

    // MARK: - Extension forwarding
    func testGetWithoutHeadersForwardsToGetWithEmptyHeaders() {
        // Given: an HTTPClient spy that records whether headers are empty
        class Spy: HTTPClient {
            var calledWithEmptyHeaders = false
            func get(url: URL, headers: [String: String]) -> AnyPublisher<Data, URLError> {
                calledWithEmptyHeaders = headers.isEmpty
                return Just(Data()).setFailureType(to: URLError.self).eraseToAnyPublisher()
            }
        }
        let spy = Spy()

        // When: calling the convenience get(url:) without headers
        _ = spy.get(url: URL(string: "https://example.com")!)

        // Then: underlying method is invoked with empty headers
        XCTAssertTrue(spy.calledWithEmptyHeaders)
    }

    // MARK: - URLSessionHTTPClient: success + headers
    func testGetWithHeaders_AppliesHeaders_AndPublishesData() {
        // Given: URLSession configured with StubURLProtocol to succeed with expected payload
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        let expected = Data("payload".utf8)
        StubURLProtocol.mode = .success(data: expected)

        // internal init is visible via @testable
        let client = URLSessionHTTPClient(configuration: config)

        let expectationReceivedData = expectation(description: "receives data")
        var received: Data?

        // When: performing GET with custom header
        client.get(
            url: URL(string: "https://example.com/ok")!,
            headers: ["X-Custom": "ABC"]
        )
        .sink(
            receiveCompletion: { _ in },
            receiveValue: { data in
                received = data
                expectationReceivedData.fulfill()
            }
        )
        .store(in: &cancellables)

        wait(for: [expectationReceivedData], timeout: 1.0)

        // Then: data matches and header applied to captured request
        XCTAssertEqual(received, expected)
        let headers = StubURLProtocol.capturedRequests.first?.allHTTPHeaderFields
        XCTAssertEqual(headers?["X-Custom"], "ABC")
    }

    // MARK: - URLSessionHTTPClient: URLError propagation
    func testGetPublishesURLErrorOnFailure() {
        // Given: StubURLProtocol configured to fail with URLError(.timedOut)
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        StubURLProtocol.mode = .failure(error: URLError(.timedOut))

        let client = URLSessionHTTPClient(configuration: config)

        let expectationReceivedError = expectation(description: "receives error")
        var received: URLError?

        // When: performing GET that triggers network failure
        client.get(url: URL(string: "https://example.com/fail")!, headers: [:])
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let e) = completion { received = e }
                    expectationReceivedError.fulfill()
                },
                receiveValue: { _ in XCTFail("should not succeed") }
            )
            .store(in: &cancellables)

        wait(for: [expectationReceivedError], timeout: 1.0)

        // Then: published error is the expected URLError
        XCTAssertEqual(received?.code, .timedOut)
    }
}

// MARK: - URLProtocol stub for URLSession
private final class StubURLProtocol: URLProtocol {
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
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: [:]
            )!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        case .failure(let error):
            // Then: propagate configured URLError
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
