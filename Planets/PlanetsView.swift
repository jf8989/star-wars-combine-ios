// App/Planets/PlanetsView.swift

import SwiftUI

/// Real Planets screen: title, search (EC), list with paging, spinner, alert.
struct PlanetsView: View {
    @ObservedObject var vm: PlanetsViewModel

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Extra Credit: Search
                HStack {
                    Image(systemName: "magnifyingglass")
                    TextField("Search planets…", text: $vm.searchTerm)
                        .textFieldStyle(.plain)
                }
                .padding(12)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                .padding(.top, 8)

                List {
                    ForEach(Array(vm.planets.enumerated()), id: \.element) {
                        index,
                        planet in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(planet.name).font(.headline)
                            Text("Climate: \(planet.climate)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(
                                "Gravity: \(planet.gravity)  •  Terrain: \(planet.terrain)"
                            )
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            Text(
                                "Diameter: \(planet.diameter)  •  Population: \(planet.population)"
                            )
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                        .onAppear {
                            vm.loadNextPageIfNeeded(currentIndex: index)
                        }
                    }

                    // Loading row (when paging)
                    if vm.isLoading && !vm.planets.isEmpty {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    }

                    // Explicit Next button (only when a next page exists and we're not currently loading)
                    if vm.canLoadMore {
                        HStack {
                            Spacer()
                            Button("Next page") {
                                // Trigger just as the last-row onAppear would
                                vm.loadNextPageIfNeeded(
                                    currentIndex: vm.planets.count - 1
                                )
                            }
                            .buttonStyle(.bordered)
                            Spacer()
                        }
                    }
                }
                .listStyle(.plain)
            }

            // Full-screen loading for first page (previously invisible)
            if vm.isLoading && vm.planets.isEmpty {
                ProgressView()
                    .scaleEffect(1.3)
                    .padding(24)
                    .background(
                        .ultraThinMaterial,
                        in: RoundedRectangle(cornerRadius: 12)
                    )
            }
        }
        .navigationTitle("Planets")
        // Single trigger to avoid double loads/log noise
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

#Preview("Planets") {
    let http = URLSessionHTTPClient()
    let svc = PlanetsServiceImpl(http: http)  // base defaults to swapi.info
    PlanetsView(vm: PlanetsViewModel(service: svc))
}
