// StarWarsCombine/Module/Screens/PlanetsScreen/Components/PlanetsSearchBar.swift

import SwiftUI

/// Standalone search bar used by the Planets screen.
struct PlanetsSearchBarView: View {
    @Binding var text: String
 
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            TextField("Search planets…", text: $text)
                .textFieldStyle(.plain)
                .textInputAutocapitalization(.never)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
    }
}
