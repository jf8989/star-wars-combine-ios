// File: /App/Planets/PlanetsView.swift

import SwiftUI

/// Planets screen: page-turn UX + local/remote search.
/// - Browsing: Prev/Next buttons and swipe gestures flip pages (10 per page).
/// - Searching: controls hide; list shows filtered results.
struct PlanetsView: View {
    @ObservedObject var vm: PlanetsViewModel

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Search bar (EC)
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
                        _,
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
                    }

                    // Loading row (server paging only)
                    if vm.isLoading && !vm.planets.isEmpty {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    }

                    // Page controls (browsing only)
                    if vm.mode == .browsing {
                        HStack(spacing: 16) {
                            if vm.currentPageDisplay > 1 {
                                Button("Prev") { vm.goPrevPage() }
                                    .buttonStyle(.bordered)
                            }
                            Text(
                                "\(vm.currentPageDisplay)/\(vm.totalPagesDisplay)"
                            )
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            if vm.canLoadMore {
                                Button("Next") { vm.goNextPage() }
                                    .buttonStyle(.bordered)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
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
        // Swipe left/right to turn pages (browsing only)
        .gesture(
            DragGesture(minimumDistance: 30)
                .onEnded { value in
                    let horizontal =
                        abs(value.translation.width)
                        > abs(value.translation.height)
                    guard horizontal, vm.mode == .browsing else { return }
                    if value.translation.width < 0 {
                        vm.goNextPage()
                    } else {
                        vm.goPrevPage()
                    }
                }
        )
        .navigationTitle("Planets")
        .onAppear {
            if vm.planets.isEmpty { vm.loadFirstPage() }
        }
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
    let svc = PlanetsServiceImpl(http: http)  // preview can use the raw service
    PlanetsView(vm: PlanetsViewModel(service: svc))
}
