// App/Main/AppMainView.swift

import SwiftUI

struct AppMainView: View {
    @State private var path: [Route] = []

    // ViewModels (persist for session)
    @StateObject private var registerVM = RegisterViewModel()
    @StateObject private var planetsVM: PlanetsViewModel = {
        let http = URLSessionHTTPClient()
        let real = PlanetsServiceImpl(http: http)  // network
        let service = LocalSearchPlanetsService(base: real)  // decorate: search is local
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
