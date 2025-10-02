// Path: StarWarsTests/PlanetsScreen/PlanetsPagerTests.swift
// Role: Pure paging math tests — stabilized guards + boundary coverage

import XCTest

@testable import StarWarsCombine

final class PlanetsPagerTests: XCTestCase {

    func testSlice_EmptyInputReturnsEmpty() {
        // Given: empty collection with pageSize=3
        let pager = PlanetsPager(pageSize: 3)
        let items: [Int] = []

        // When: slicing page 0
        let page = pager.slice(items)

        // Then: slice is empty; currentPage stays 0; totalPages reports 1 (single empty page)
        XCTAssertTrue(page.isEmpty)
        XCTAssertEqual(pager.currentPage, 0)
        XCTAssertEqual(pager.totalPages(totalCount: items.count), 1)
    }

    func testSlice_FirstMiddleLastPages() {
        // Given: 10 items with pageSize=4 → pages: [1..4], [5..8], [9..10]
        var pager = PlanetsPager(pageSize: 4)
        let items = Array(1...10)

        // When: take first, advance, take middle, advance, take last
        let first = pager.slice(items)
        _ = pager.stepForwardIfPossible(totalCount: items.count)
        let middle = pager.slice(items)
        _ = pager.stepForwardIfPossible(totalCount: items.count)
        let last = pager.slice(items)

        // Then: slices match expected windows; totalPages == 3
        XCTAssertEqual(first, [1, 2, 3, 4])
        XCTAssertEqual(middle, [5, 6, 7, 8])
        XCTAssertEqual(last, [9, 10])
        XCTAssertEqual(pager.totalPages(totalCount: items.count), 3)
    }

    func testHasNextAndStepGuards() {
        // Given: 11 items with pageSize=5 → pages: [0–4], [5–9], [10]
        var pager = PlanetsPager(pageSize: 5)
        let items = Array(0..<11)

        // Sanity: initial state and counts
        XCTAssertEqual(pager.pageSize, 5)
        XCTAssertEqual(pager.currentPage, 0)
        XCTAssertEqual(items.count, 11)

        // When / Then: forward navigation respects bounds
        XCTAssertTrue(pager.hasNext(totalCount: items.count))  // page 0 → next exists
        XCTAssertTrue(pager.stepForwardIfPossible(totalCount: items.count))  // 0 → 1
        XCTAssertTrue(pager.hasNext(totalCount: items.count))  // page 1 → next exists
        XCTAssertTrue(pager.stepForwardIfPossible(totalCount: items.count))  // 1 → 2
        XCTAssertFalse(pager.hasNext(totalCount: items.count))  // page 2 is last
        XCTAssertFalse(pager.stepForwardIfPossible(totalCount: items.count))  // cannot advance
    }

    func testStepBackwardRespectsLowerBound() {
        // Given: pageSize=3; after one forward step we are on page 1
        var pager = PlanetsPager(pageSize: 3)
        let items = Array(1...7)
        _ = pager.stepForwardIfPossible(totalCount: items.count)  // reach page 1

        // When: stepping backward twice
        XCTAssertTrue(pager.stepBackward())
        // Then: cannot go below page 0; slice remains first page
        XCTAssertFalse(pager.stepBackward(), "Cannot go below page 0")
        XCTAssertEqual(pager.currentPage, 0)
        XCTAssertEqual(pager.slice(items), [1, 2, 3])
    }

    /// Documents the boundary behavior: when totalCount is an exact multiple of pageSize
    /// and we're at page 0 with default pageSize=10, hasNext is false for 10 items.
    func testHasNext_WithExactMultipleBoundary() {
        // Given: default pager (pageSize=10) and exactly 10 items
        var pager = PlanetsPager()  // default = 10
        let items = Array(0..<10)  // exactly one full page

        // When / Then: next page does not exist; cannot step forward
        XCTAssertFalse(
            pager.hasNext(totalCount: items.count),
            "At page 0 with pageSize=10 and 10 items, 10 < 10 is false"
        )
        XCTAssertFalse(
            pager.stepForwardIfPossible(totalCount: items.count),
            "Cannot step forward because there is no next page"
        )
    }
}
