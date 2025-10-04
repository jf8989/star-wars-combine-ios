// App/Planets/UIState/PlanetsPager.swift

import Foundation

struct PlanetsPager {
    private(set) var currentPage: Int = 0  // 0-based
    let pageSize: Int

    init(pageSize: Int = 10) {
        self.pageSize = pageSize
    }

    // Reset to first page
    mutating func reset() {
        currentPage = 0
    }

    // Slice the given array for the current page
    func slice<T>(_ items: [T]) -> [T] {
        let start = currentPage * pageSize
        let end = min(items.count, start + pageSize)
        guard start < end else { return [] }
        return Array(items[start..<end])
    }

    // Do we have a forward page locally?
    func hasNext(totalCount: Int) -> Bool {
        (currentPage + 1) * pageSize < totalCount
    }

    // Total pages for a fixed-size list (>= 1)
    func totalPages(totalCount: Int) -> Int {
        max(1, Int(ceil(Double(totalCount) / Double(pageSize))))
    }

    // Move forward if possible (returns true if advanced)
    @discardableResult
    mutating func stepForwardIfPossible(totalCount: Int) -> Bool {
        guard hasNext(totalCount: totalCount) else { return false }
        currentPage += 1
        return true
    }

    // Move backward if possible (returns true if moved)
    @discardableResult
    mutating func stepBackward() -> Bool {
        guard currentPage > 0 else { return false }
        currentPage -= 1
        return true
    }
}
