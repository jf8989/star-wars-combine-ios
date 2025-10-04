// StarWarsCombine/Module/Screens/PlanetsScreen/Components/PlanetCard.swift

import SwiftUI

/// Visual card representing a single Planet.
struct PlanetCardView: View {
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
                    PlanetStatRowView(
                        title: "Climate",
                        systemImage: "wind",
                        value: planet.climate
                    )
                    PlanetStatRowView(
                        title: "Terrain",
                        systemImage: "leaf",
                        value: planet.terrain
                    )
                }
                GridRow {
                    PlanetStatRowView(
                        title: "Gravity",
                        systemImage: "g.circle",
                        value: planet.gravity
                    )
                    PlanetStatRowView(
                        title: "Diameter",
                        systemImage: "ruler",
                        value: planet.diameter
                    )
                }
                GridRow {
                    PlanetStatRowView(
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
