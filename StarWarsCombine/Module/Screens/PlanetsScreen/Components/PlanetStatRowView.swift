// StarWarsCombine/Module/Screens/PlanetsScreen/Components/PlanetStatRow.swift

import SwiftUI

/// Tiny subview used by PlanetCard to render a key/value with an icon.
struct PlanetStatRowView: View {
    let title: String
    let systemImage: String
    let value: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage).imageScale(.small)
            Text("\(title): ").fontWeight(.semibold)
            Text(value).foregroundStyle(.primary)
        }
    }
}
