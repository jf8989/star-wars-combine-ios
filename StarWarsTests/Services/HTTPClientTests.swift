/// Path: StarWarsTests/Services/HTTPClientTests.swift
/// Role: Cover extension get(url:) forwards to headers version + URLSession client behaviors

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
        class HTTPClientSpy: HTTPClient {
            var calledWithEmptyHeaders = false
            func get(url: URL, headers: [String: String]) -> AnyPublisher<Data, URLError> {
                calledWithEmptyHeaders = headers.isEmpty
                return Just(Data()).setFailureType(to: URLError.self).eraseToAnyPublisher()
            }
        }
        let spyClient = HTTPClientSpy()

        // When: calling the convenience get(url:) without headers
        _ = spyClient.get(url: URL(string: "https://example.com")!)

        // Then: underlying method is invoked with empty headers
        XCTAssertTrue(spyClient.calledWithEmptyHeaders)
    }

    // MARK: - URLSessionHTTPClient: success + headers
    func testGetWithHeaders_AppliesHeaders_AndPublishesData() {
        // Given: URLSession configured with StubURLProtocol to succeed with expected payload
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        let expectedData = Data("payload".utf8)
        StubURLProtocol.mode = .success(data: expectedData)

        // internal init is visible via @testable
        let client = URLSessionHTTPClient(configuration: configuration)

        let expectationReceivedData = expectation(description: "receives data")
        var receivedData: Data?

        // When: performing GET with custom header
        client.get(
            url: URL(string: "https://example.com/ok")!,
            headers: ["X-Custom": "ABC"]
        )
        .sink(
            receiveCompletion: { _ in },
            receiveValue: { data in
                receivedData = data
                expectationReceivedData.fulfill()
            }
        )
        .store(in: &cancellables)

        wait(for: [expectationReceivedData], timeout: 1.0)

        // Then: data matches and header applied to captured request
        XCTAssertEqual(receivedData, expectedData)
        let allHeaders = StubURLProtocol.capturedRequests.first?.allHTTPHeaderFields
        XCTAssertEqual(allHeaders?["X-Custom"], "ABC")
    }

    // MARK: - URLSessionHTTPClient: URLError propagation
    func testGetPublishesURLErrorOnFailure() {
        // Given: StubURLProtocol configured to fail with URLError(.timedOut)
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        StubURLProtocol.mode = .failure(error: URLError(.timedOut))

        let client = URLSessionHTTPClient(configuration: configuration)

        let expectationReceivedError = expectation(description: "receives error")
        var receivedError: URLError?

        // When: performing GET that triggers network failure
        client.get(url: URL(string: "https://example.com/fail")!, headers: [:])
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let urlError) = completion { receivedError = urlError }
                    expectationReceivedError.fulfill()
                },
                receiveValue: { _ in XCTFail("should not succeed") }
            )
            .store(in: &cancellables)

        wait(for: [expectationReceivedError], timeout: 1.0)

        // Then: published error is the expected URLError
        XCTAssertEqual(receivedError?.code, .timedOut)
    }
}
