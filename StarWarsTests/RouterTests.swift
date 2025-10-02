/// Path: StarWarsTests/RouterTests.swift
/// Role: Sanity tests for Router navigation stack

import XCTest

@testable import StarWarsCombine

final class RouterTests: XCTestCase {
    func testPushAddsRoute() {
        // Given a fresh router
        let router = Router()
        // When we push a route
        router.push(.planets)
        // Then the path contains that route
        XCTAssertEqual(router.path, [.planets])
    }

    func testPopRemovesLastRoute() {
        // Given a router with two routes
        let router = Router()
        router.push(.register)
        router.push(.planets)
        // When we pop
        router.pop()
        // Then the last route is removed
        XCTAssertEqual(router.path, [.register])
    }

    func testPopOnEmptyDoesNothing() {
        // Given an empty router
        let router = Router()
        // When we pop
        router.pop()
        // Then the path stays empty
        XCTAssertTrue(router.path.isEmpty)
    }

    func testResetReplacesPath() {
        // Given a router with an existing path
        let router = Router()
        router.push(.register)
        // When we reset to a new path
        router.reset(to: [.planets])
        // Then the path is replaced
        XCTAssertEqual(router.path, [.planets])
    }
}
