// App/Planets/Helpers/PlanetsSorting.swift

import Foundation

/// Presentation-level sort policy for planets.
public enum PlanetsSorting {
    /// Case-insensitive A→Z by name.
    public static func alpha(_ items: [Planet]) -> [Planet] {
        items.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name)
                == .orderedAscending
        }
    }
}
