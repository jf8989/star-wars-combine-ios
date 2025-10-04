// App/Planets/Helpers/PlanetsSorting.swift

import Foundation

/// Presentation-level sort policy for planets.
enum PlanetsSorting {
    /// Case-insensitive A→Z by name.
    static func alpha(_ items: [Planet]) -> [Planet] {
        items.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name)
                == .orderedAscending
        }
    }
}
