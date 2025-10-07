// StarWarsCombine/Module/Screens/PlanetsScreen/Components/PlanetsPagerView.swift

import SwiftUI

/// Page container: cards list + controls + swipe gestures + transitions.
/// Works for both client-side and server-side paging (via ViewModel).
struct PlanetsPagerView: View {
    @ObservedObject var vm: PlanetsViewModel

    private var pageAnimation: Animation {
        .spring(response: 0.35, dampingFraction: 0.85, blendDuration: 0.15)
    }

    var body: some View {
        // Directional transitions
        let insertion: AnyTransition =
            .move(edge: vm.pageDirection == .forward ? .trailing : .leading)
            .combined(with: .opacity)
        let removal: AnyTransition =
            .move(edge: vm.pageDirection == .forward ? .leading : .trailing)
            .combined(with: .opacity)

        VStack(spacing: 8) {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(Array(vm.displayPlanets.enumerated()), id: \.element) {
                        _,
                        planet in
                        PlanetCardView(planet: planet)
                            .transition(
                                .opacity.combined(with: .scale(scale: 0.98))
                            )
                    }

                    if vm.isLoading && !vm.displayPlanets.isEmpty {
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
        .animation(pageAnimation, value: vm.currentPage)
        .animation(pageAnimation, value: vm.mode)
        // Swipe to flip pages (browsing only)
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
    }

    private var controlsBar: some View {
        HStack(spacing: 14) {
            if vm.currentPageDisplay > 1 {
                Button {
                    withAnimation(pageAnimation) { vm.goPrevPage() }
                } label: {
                    Label("Prev", systemImage: "chevron.left").labelStyle(
                        .iconOnly
                    )
                }
                .buttonStyle(.bordered)
            }

            Text("\(vm.currentPageDisplay)/\(vm.totalPagesDisplay)")
                .font(.footnote)
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color(.tertiarySystemFill)))

            if vm.canLoadMore {
                Button {
                    withAnimation(pageAnimation) { vm.goNextPage() }
                } label: {
                    Label("Next", systemImage: "chevron.right").labelStyle(
                        .iconOnly
                    )
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }
}
