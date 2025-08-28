// File: /View/AppMainView.swift

import SwiftUI

struct AppMainView: View {
    @State private var path: [Route] = []

    var body: some View {
        NavigationStack(path: $path) {
            RegisterPlaceholderView(onSignUp: {
                // Phase 0: show nav wiring; real validation arrives in Phase 2/3.
                path.append(.planets)
            })
            .navigationTitle("Register")
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .register:
                    RegisterPlaceholderView(onSignUp: { path.append(.planets) })
                case .planets:
                    PlanetsPlaceholderView()
                }
            }
        }
    }
}

private struct RegisterPlaceholderView: View {
    let onSignUp: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Register Screen")
                .font(.title2)
            Text("Phase 0 placeholder — fields & validation land in Phase 2/3.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            Button("Sign Up → Planets") {
                onSignUp()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

private struct PlanetsPlaceholderView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Planets")
                .font(.largeTitle)
            Text("Phase 0 placeholder — list & pagination arrive later.")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }
}

#Preview("iPhone") {
    AppMainView()
}

#Preview("iPhone") {
    AppMainView()
}
