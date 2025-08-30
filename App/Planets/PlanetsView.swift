// File: /App/Planets/PlanetsView.swift

import SwiftUI

/// Planets screen: animated page-turn UX + local/remote search.
/// - Browsing: Prev/Next buttons and swipe gestures flip pages (10 per page) with slide+fade.
/// - Searching: controls hide; list shows filtered results (also alpha-sorted).
struct PlanetsView: View {
    @ObservedObject var vm: PlanetsViewModel

    // Animation presets
    private var pageAnimation: Animation {
        .spring(response: 0.35, dampingFraction: 0.85, blendDuration: 0.15)
    }

    var body: some View {
        ZStack {
            // Subtle backdrop
            LinearGradient(
                colors: [
                    Color(.systemBackground), Color(.secondarySystemBackground),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 12) {
                searchBar

                // Page container with directional transition
                pageContainer
                    .animation(pageAnimation, value: vm.currentPage)
                    .animation(pageAnimation, value: vm.mode)
            }
            .padding(.top, 8)

            // First-page loading
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
        // Swipe left/right to turn pages (browsing only)
        .gesture(
            DragGesture(minimumDistance: 30)
                .onEnded { value in
                    let horizontal =
                        abs(value.translation.width)
                        > abs(value.translation.height)
                    guard horizontal, vm.mode == .browsing else { return }
                    withAnimation(pageAnimation) {
                        if value.translation.width < 0 {
                            vm.goNextPage()
                        } else {
                            vm.goPrevPage()
                        }
                    }
                }
        )
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

    // MARK: - Pieces

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            TextField("Search planets…", text: $vm.searchTerm)
                .textFieldStyle(.plain)
                .textInputAutocapitalization(.never)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
    }

    @ViewBuilder
    private var pageContainer: some View {
        // Directional transitions
        let insertion: AnyTransition = .move(
            edge: vm.pageDirection == .forward ? .trailing : .leading
        ).combined(with: .opacity)
        let removal: AnyTransition = .move(
            edge: vm.pageDirection == .forward ? .leading : .trailing
        ).combined(with: .opacity)

        VStack(spacing: 8) {
            // Cards list
            ScrollView {
                LazyVStack(spacing: 12, pinnedViews: []) {
                    ForEach(Array(vm.planets.enumerated()), id: \.element) {
                        _,
                        planet in
                        PlanetCard(planet: planet)
                            .transition(
                                .opacity.combined(with: .scale(scale: 0.98))
                            )
                    }

                    if vm.isLoading && !vm.planets.isEmpty {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }

                    if vm.mode == .browsing {
                        controlsBar
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
        .id(vm.currentPage)  // treat each page as a new view
        .transition(.asymmetric(insertion: insertion, removal: removal))
    }

    private var controlsBar: some View {
        HStack(spacing: 14) {
            if vm.currentPageDisplay > 1 {
                Button {
                    withAnimation(pageAnimation) { vm.goPrevPage() }
                } label: {
                    Label("Prev", systemImage: "chevron.left")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.bordered)
            }

            Text("\(vm.currentPageDisplay)/\(vm.totalPagesDisplay)")
                .font(.footnote)
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(Color(.tertiarySystemFill))
                )

            if vm.canLoadMore {
                Button {
                    withAnimation(pageAnimation) { vm.goNextPage() }
                } label: {
                    Label("Next", systemImage: "chevron.right")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }
}

// MARK: - Row Card

private struct PlanetCard: View {
    let planet: Planet

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Image(systemName: "globe.europe.africa.fill")
                Text(planet.name)
                    .font(.headline)
                Spacer(minLength: 0)
            }

            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 6)
            {
                GridRow {
                    label("Climate", systemImage: "wind", value: planet.climate)
                    label("Terrain", systemImage: "leaf", value: planet.terrain)
                }
                GridRow {
                    label(
                        "Gravity",
                        systemImage: "g.circle",
                        value: planet.gravity
                    )
                    label(
                        "Diameter",
                        systemImage: "ruler",
                        value: planet.diameter
                    )
                }
                GridRow {
                    label(
                        "Population",
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

    @ViewBuilder
    private func label(_ title: String, systemImage: String, value: String)
        -> some View
    {
        HStack(spacing: 6) {
            Image(systemName: systemImage).imageScale(.small)
            Text("\(title): ")
                .fontWeight(.semibold)
            Text(value)
                .foregroundStyle(.primary)
        }
    }
}
