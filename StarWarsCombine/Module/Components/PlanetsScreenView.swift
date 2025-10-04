// App/Planets/Components/PlanetsScreen.swift

import SwiftUI

/// Screen shell: backdrop, search, pager, lifecycle & alert.
struct PlanetsScreenView: View {
    @ObservedObject var viewModel: PlanetsViewModel

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
                PlanetsSearchBarView(text: $viewModel.searchTerm)
                PlanetsPagerView(vm: viewModel)
            }
            .padding(.top, 8)

            if viewModel.isLoading && viewModel.displayPlanets.isEmpty {
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
        .onAppear { if viewModel.displayPlanets.isEmpty { viewModel.loadFirstPage() } }
        .alert(
            "Network error",
            isPresented: Binding(
                get: { viewModel.alert != nil },
                set: { if !$0 { viewModel.alert = nil } }
            )
        ) {
            Button("OK", role: .cancel) { viewModel.alert = nil }
        } message: {
            Text(viewModel.alert ?? "")
        }
    }
}
