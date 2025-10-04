// Path: App/Main/AppMainView.swift
// Role: Root view, binds NavigationStack to Router and maps destinations

import SwiftUI

struct AppMainView: View {
    @StateObject private var router = Router()

    var body: some View {
        NavigationStack(path: $router.path) {

            // Entry screen: Register
            RegisterView()
                .navigationDestination(for: AppRoutes.self) { route in
                    switch route {

                    case .register:
                        RegisterView()

                    case .planets:
                        PlanetsView()
                    }
                }
        }
        .environmentObject(router)
    }
}

#Preview("App") {
    AppMainView()
        .environmentObject(Router())
}
