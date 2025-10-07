/// Path: StarWarsTests/Services/PlanetsServiceLiveTests.swift
/// Role: Decode branches + error mapping + URL building via MockHTTPClient

import Combine
import XCTest

@testable import StarWarsCombine

final class PlanetsServiceLiveTests: XCTestCase {

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Lifecycle

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    // MARK: - URL construction

    func testFetchFirstPage_UsesPlanetsPath() {
        // Given: MockHTTPClient scripted with valid empty JSON; live service under test
        let mockHTTPClient = MockHTTPClient()
        mockHTTPClient.response = .success(Data("[]".utf8))  // valid empty-array JSON

        let serviceUnderTest = PlanetsServiceLive(http: mockHTTPClient)
        let expectFetchFirstPageCompletes = expectation(description: "fetch first page completes")

        // When: fetching first page
        serviceUnderTest.fetchFirstPage()
            .sink(
                receiveCompletion: { _ in expectFetchFirstPageCompletes.fulfill() },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)

        wait(for: [expectFetchFirstPageCompletes], timeout: 1.0)

        // Then: request path contains `/planets/` and URL is well-formed
        guard let requestedURL = mockHTTPClient.requestedURLs.first else {
            return XCTFail("No URL was requested by the service.")
        }
        let requestedAbsolute = requestedURL.absoluteString
        XCTAssertTrue(
            requestedAbsolute.contains("/planets/"),
            "Expected /planets/ in the URL, got: \(requestedAbsolute)"
        )
        XCTAssertTrue(
            Set(["http", "https"]).contains(requestedURL.scheme ?? ""),
            "Unexpected URL scheme: \(String(describing: requestedURL.scheme))"
        )
        XCTAssertFalse((requestedURL.host ?? "").isEmpty, "Expected a non-empty host in the requested URL.")
    }

    // MARK: - Decode branches

    func testDecode_SwapiDevPageShape_SetsNextAndMapsResults() throws {
        // Given: swapi.dev page-shaped JSON (has `next` + `results`) scripted as success
        let jsonData = try DataLoader.loadJSON(named: "planets_swapi_page")
        let mockHTTPClient = MockHTTPClient()
        mockHTTPClient.response = .success(jsonData)

        let serviceUnderTest = PlanetsServiceLive(http: mockHTTPClient)
        let expectSwapiPageDecoded = expectation(description: "decode swapi.dev page shape")

        var receivedPage: PlanetsPage?

        // When: fetchFirstPage()
        serviceUnderTest.fetchFirstPage()
            .sink(
                receiveCompletion: { _ in expectSwapiPageDecoded.fulfill() },
                receiveValue: { page in
                    receivedPage = page
                }
            )
            .store(in: &cancellables)

        wait(for: [expectSwapiPageDecoded], timeout: 1.0)

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
        let expectSwapiInfoArrayDecoded = expectation(description: "decode swapi.info array shape")

        var receivedPage: PlanetsPage?

        // When: fetchFirstPage()
        serviceUnderTest.fetchFirstPage()
            .sink(
                receiveCompletion: { _ in expectSwapiInfoArrayDecoded.fulfill() },
                receiveValue: { page in
                    receivedPage = page
                }
            )
            .store(in: &cancellables)

        wait(for: [expectSwapiInfoArrayDecoded], timeout: 1.0)

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
        let expectSingleObjectDecoded = expectation(description: "decode single object shape")

        var receivedPage: PlanetsPage?

        // When: fetchFirstPage()
        serviceUnderTest.fetchFirstPage()
            .sink(
                receiveCompletion: { _ in expectSingleObjectDecoded.fulfill() },
                receiveValue: { page in
                    receivedPage = page
                }
            )
            .store(in: &cancellables)

        wait(for: [expectSingleObjectDecoded], timeout: 1.0)

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
        let expectMalformedDecodeCompletes = expectation(description: "malformed decode completes")

        var receivedAppError: AppError?

        // When: fetchFirstPage()
        serviceUnderTest.fetchFirstPage()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        receivedAppError = error
                    }
                    expectMalformedDecodeCompletes.fulfill()
                },
                receiveValue: { _ in
                    XCTFail("Should not decode malformed payload")
                }
            )
            .store(in: &cancellables)

        wait(for: [expectMalformedDecodeCompletes], timeout: 1.0)

        // Then: error is mapped to `.message` with neutral text
        guard case .message(let text)? = receivedAppError else {
            return XCTFail("Expected .message error, got \(String(describing: receivedAppError))")
        }
        XCTAssertTrue(text.contains("Decode failed"), "Keeps user-facing text neutral/short")
    }

    func testNetworkFailure_BubblesAsNetworkError() {
        // Given: MockHTTPClient scripted to fail with URLError.timedOut
        let mockHTTPClient = MockHTTPClient()
        mockHTTPClient.response = .failure(URLError(.timedOut))

        let serviceUnderTest = PlanetsServiceLive(http: mockHTTPClient)
        let expectNetworkFailureCompletes = expectation(description: "network failure completes")

        var receivedAppError: AppError?

        // When: fetchFirstPage()
        serviceUnderTest.fetchFirstPage()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        receivedAppError = error
                    }
                    expectNetworkFailureCompletes.fulfill()
                },
                receiveValue: { _ in
                    XCTFail("Should not succeed when HTTP client fails")
                }
            )
            .store(in: &cancellables)

        wait(for: [expectNetworkFailureCompletes], timeout: 1.0)

        // Then: error is bubbled as `.network`
        guard case .network = receivedAppError else {
            return XCTFail("Expected .network error, got \(String(describing: receivedAppError))")
        }
    }
}
