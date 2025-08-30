// App/Planets/Components/PlanetCard.swift

import SwiftUI

/// Visual card representing a single Planet.
struct PlanetCard: View {
    let planet: Planet

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Image(systemName: "globe.europe.africa.fill")
                Text(planet.name).font(.headline)
                Spacer(minLength: 0)
            }

            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 6)
            {
                GridRow {
                    PlanetStatRow(
                        title: "Climate",
                        systemImage: "wind",
                        value: planet.climate
                    )
                    PlanetStatRow(
                        title: "Terrain",
                        systemImage: "leaf",
                        value: planet.terrain
                    )
                }
                GridRow {
                    PlanetStatRow(
                        title: "Gravity",
                        systemImage: "g.circle",
                        value: planet.gravity
                    )
                    PlanetStatRow(
                        title: "Diameter",
                        systemImage: "ruler",
                        value: planet.diameter
                    )
                }
                GridRow {
                    PlanetStatRow(
                        title: "Population",
                        systemImage: "person.3",
                        value: planet.population
                    )
                    Spacer()
                }
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(radius: 2, y: 1)
        )
    }
}
