// File: /View/AppMainView.swift
// PATCH: replace the Phase-0 placeholder screens with real views + VM injection.

import SwiftUI

struct AppMainView: View {
    @State private var path: [Route] = []

    // ViewModels (persist for session)
    @StateObject private var registerVM = RegisterViewModel()
    @StateObject private var planetsVM: PlanetsViewModel = {
        let http = URLSessionHTTPClient()
        let service = PlanetsServiceImpl(http: http)  // base defaults to swapi.info
        return PlanetsViewModel(service: service)
    }()

    var body: some View {
        NavigationStack(path: $path) {
            RegisterView(vm: registerVM)
                .onChange(of: registerVM.shouldNavigateToPlanets) { _, should in
                    if should {
                        path.append(.planets)
                        registerVM.shouldNavigateToPlanets = false
                    }
                }
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .register:
                        RegisterView(vm: registerVM)
                    case .planets:
                        PlanetsView(vm: planetsVM)
                    }
                }
        }
    }
}

#Preview("App") {
    AppMainView()
}
