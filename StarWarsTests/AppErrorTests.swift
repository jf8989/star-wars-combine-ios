/// Path: StarWarsTests/AppErrorTests.swift
/// Role: User-facing error message mapping

import XCTest

@testable import StarWarsCombine

final class AppErrorTests: XCTestCase {

    func testUserMessage_Network() {
        // Given a network error
        // When we read its userMessage
        let message = AppError.network(URLError(.notConnectedToInternet)).userMessage
        // Then it maps to the offline message
        XCTAssertEqual(message, "Network connection appears to be offline.")
    }

    func testUserMessage_Decode() {
        // Given a decode error
        struct DummyError: Error {}
        // When we read its userMessage
        let message = AppError.decode(DummyError()).userMessage
        // Then it maps to the generic decode failure
        XCTAssertEqual(message, "We couldn't read the server response.")
    }

    func testUserMessage_Http() {
        // Given an HTTP error
        // When we read its userMessage
        let message = AppError.http(status: 503).userMessage
        // Then it includes the status code
        XCTAssertEqual(message, "Server responded with status 503.")
    }

    func testUserMessage_CustomMessage() {
        // Given a custom message error
        // When we read its userMessage
        let message = AppError.message("Custom").userMessage
        // Then it surfaces the exact message
        XCTAssertEqual(message, "Custom")
    }
}
