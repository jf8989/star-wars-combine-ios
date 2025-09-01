// App/Planets/UIState/PlanetsPager.swift

import Foundation

/// Pure paging state & slicing for page-turn UX.
/// UI and network remain outside; this is just math over an array length.
public struct PlanetsPager {
    public private(set) var currentPage: Int = 0  // 0-based
    public let pageSize: Int
 
    public init(pageSize: Int = 10) {
        self.pageSize = pageSize
    }

    // Reset to first page
    public mutating func reset() {
        currentPage = 0
    }

    // Slice the given array for the current page
    public func slice<T>(_ items: [T]) -> [T] {
        let start = currentPage * pageSize
        let end = min(items.count, start + pageSize)
        guard start < end else { return [] }
        return Array(items[start..<end])
    }

    // Do we have a forward page locally?
    public func hasNext(totalCount: Int) -> Bool {
        (currentPage + 1) * pageSize < totalCount
    }

    // Total pages for a fixed-size list (>= 1)
    public func totalPages(totalCount: Int) -> Int {
        max(1, Int(ceil(Double(totalCount) / Double(pageSize))))
    }

    // Move forward if possible (returns true if advanced)
    @discardableResult
    public mutating func stepForwardIfPossible(totalCount: Int) -> Bool {
        guard hasNext(totalCount: totalCount) else { return false }
        currentPage += 1
        return true
    }

    // Move backward if possible (returns true if moved)
    @discardableResult
    public mutating func stepBackward() -> Bool {
        guard currentPage > 0 else { return false }
        currentPage -= 1
        return true
    }
}
