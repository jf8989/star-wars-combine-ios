// App/Planets/Components/PlanetsScreen.swift

import SwiftUI

/// Screen shell: backdrop, search, pager, lifecycle & alert.
struct PlanetsScreen: View {
    @ObservedObject var vm: PlanetsViewModel

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(.systemBackground), Color(.secondarySystemBackground),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 12) {
                PlanetsSearchBar(text: $vm.searchTerm)
                PlanetsPagerView(vm: vm)
            }
            .padding(.top, 8)

            if vm.isLoading && vm.planets.isEmpty {
                ProgressView()
                    .scaleEffect(1.2)
                    .padding(24)
                    .background(
                        .ultraThinMaterial,
                        in: RoundedRectangle(cornerRadius: 16)
                    )
            }
        }
        .navigationTitle("Planets")
        .onAppear { if vm.planets.isEmpty { vm.loadFirstPage() } }
        .alert(
            "Network error",
            isPresented: Binding(
                get: { vm.alert != nil },
                set: { if !$0 { vm.alert = nil } }
            )
        ) {
            Button("OK", role: .cancel) { vm.alert = nil }
        } message: {
            Text(vm.alert ?? "")
        }
    }
}
