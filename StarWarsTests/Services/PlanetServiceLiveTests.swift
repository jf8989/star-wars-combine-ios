// Path: StarWarsTests/Services/PlanetsServiceLiveTests.swift
// Role: Decode branches + error mapping + URL building via MockHTTPClient

import Combine
import XCTest

@testable import StarWarsCombine

final class PlanetsServiceLiveTests: XCTestCase {

    private var subscriptions = Set<AnyCancellable>()

    // MARK: - URL construction

    func testFetchFirstPage_UsesPlanetsPath() {
        // Given: MockHTTPClient scripted with valid empty JSON; live service under test
        let mockHTTPClient = MockHTTPClient()
        mockHTTPClient.response = .success(Data("[]".utf8))  // valid empty-array JSON

        let serviceUnderTest = PlanetsServiceLive(http: mockHTTPClient)
        let expectationFinished = expectation(description: "fetch first page completes")

        // When: fetching first page
        serviceUnderTest.fetchFirstPage()
            .sink(
                receiveCompletion: { _ in expectationFinished.fulfill() },
                receiveValue: { _ in }
            )
            .store(in: &subscriptions)

        wait(for: [expectationFinished], timeout: 1.0)

        // Then: request path contains `/planets/`
        let requested = mockHTTPClient.requestedURLs.first?.absoluteString ?? ""
        XCTAssertTrue(requested.contains("/planets/"), "Expected /planets/ in the URL, got: \(requested)")
    }

    // MARK: - Decode branches

    func testDecode_SwapiDevPageShape_SetsNextAndMapsResults() throws {
        // Given: swapi.dev page-shaped JSON (has `next` + `results`) scripted as success
        let jsonData = try DataLoader.loadJSON(named: "planets_swapi_page")
        let mockHTTPClient = MockHTTPClient()
        mockHTTPClient.response = .success(jsonData)

        let serviceUnderTest = PlanetsServiceLive(http: mockHTTPClient)
        let expectationDecoded = expectation(description: "decode swapi.dev page shape")

        var receivedPage: PlanetsPage?

        // When: fetchFirstPage()
        serviceUnderTest.fetchFirstPage()
            .sink(
                receiveCompletion: { _ in expectationDecoded.fulfill() },
                receiveValue: { page in
                    receivedPage = page
                }
            )
            .store(in: &subscriptions)

        wait(for: [expectationDecoded], timeout: 1.0)

        // Then: `next` URL present; planets mapped correctly
        XCTAssertNotNil(receivedPage?.next, "Expected `next` URL parsed from string")
        XCTAssertEqual(receivedPage?.planets.first?.name, "Alderaan")
        XCTAssertEqual(receivedPage?.planets.count, 2)
    }

    func testDecode_SwapiInfoArrayShape_NoNext() throws {
        // Given: swapi.info array-shaped JSON (no `next`) scripted as success
        let jsonData = try DataLoader.loadJSON(named: "planets_swapi_info_array")
        let mockHTTPClient = MockHTTPClient()
        mockHTTPClient.response = .success(jsonData)

        let serviceUnderTest = PlanetsServiceLive(http: mockHTTPClient)
        let expectationDecoded = expectation(description: "decode swapi.info array shape")

        var receivedPage: PlanetsPage?

        // When: fetchFirstPage()
        serviceUnderTest.fetchFirstPage()
            .sink(
                receiveCompletion: { _ in expectationDecoded.fulfill() },
                receiveValue: { page in
                    receivedPage = page
                }
            )
            .store(in: &subscriptions)

        wait(for: [expectationDecoded], timeout: 1.0)

        // Then: no `next`; names mapped as expected
        XCTAssertNil(receivedPage?.next, "Array shape should not include `next`")
        XCTAssertEqual(receivedPage?.planets.map(\.name), ["Endor", "Hoth"])
    }

    func testDecode_SingleObject_IsWrappedAsSingleItemPage() throws {
        // Given: single-object JSON scripted as success
        let jsonData = try DataLoader.loadJSON(named: "planet_single")
        let mockHTTPClient = MockHTTPClient()
        mockHTTPClient.response = .success(jsonData)

        let serviceUnderTest = PlanetsServiceLive(http: mockHTTPClient)
        let expectationDecoded = expectation(description: "decode single object shape")

        var receivedPage: PlanetsPage?

        // When: fetchFirstPage()
        serviceUnderTest.fetchFirstPage()
            .sink(
                receiveCompletion: { _ in expectationDecoded.fulfill() },
                receiveValue: { page in
                    receivedPage = page
                }
            )
            .store(in: &subscriptions)

        wait(for: [expectationDecoded], timeout: 1.0)

        // Then: page wraps exactly one planet; name matches payload
        XCTAssertNil(receivedPage?.next)
        XCTAssertEqual(receivedPage?.planets.count, 1)
        XCTAssertEqual(receivedPage?.planets.first?.name, "Tatooine")
    }

    // MARK: - Error mapping

    func testMalformedPayload_MapsToMessageError() throws {
        // Given: malformed JSON scripted as success (decode should fail)
        let jsonData = try DataLoader.loadJSON(named: "planets_malformed")
        let mockHTTPClient = MockHTTPClient()
        mockHTTPClient.response = .success(jsonData)

        let serviceUnderTest = PlanetsServiceLive(http: mockHTTPClient)
        let expectationCompleted = expectation(description: "malformed decode completes")

        var receivedError: AppError?

        // When: fetchFirstPage()
        serviceUnderTest.fetchFirstPage()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        receivedError = error
                    }
                    expectationCompleted.fulfill()
                },
                receiveValue: { _ in
                    XCTFail("Should not decode malformed payload")
                }
            )
            .store(in: &subscriptions)

        wait(for: [expectationCompleted], timeout: 1.0)

        // Then: error is mapped to `.message` with neutral text
        guard case .message(let text)? = receivedError else {
            return XCTFail("Expected .message error, got \(String(describing: receivedError))")
        }
        XCTAssertTrue(text.contains("Decode failed"), "Keeps user-facing text neutral/short")
    }

    func testNetworkFailure_BubblesAsNetworkError() {
        // Given: MockHTTPClient scripted to fail with URLError.timedOut
        let mockHTTPClient = MockHTTPClient()
        mockHTTPClient.response = .failure(URLError(.timedOut))

        let serviceUnderTest = PlanetsServiceLive(http: mockHTTPClient)
        let expectationCompleted = expectation(description: "network failure completes")

        var receivedError: AppError?

        // When: fetchFirstPage()
        serviceUnderTest.fetchFirstPage()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        receivedError = error
                    }
                    expectationCompleted.fulfill()
                },
                receiveValue: { _ in
                    XCTFail("Should not succeed when HTTP client fails")
                }
            )
            .store(in: &subscriptions)

        wait(for: [expectationCompleted], timeout: 1.0)

        // Then: error is bubbled as `.network`
        guard case .network = receivedError else {
            return XCTFail("Expected .network error, got \(String(describing: receivedError))")
        }
    }
}
