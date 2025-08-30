// /App/Planets/PlanetsView.swift

import SwiftUI

/// Thin wrapper. Body only composes subviews per mandate.
struct PlanetsView: View {
    @ObservedObject var vm: PlanetsViewModel
    var body: some View {
        PlanetsScreen(vm: vm)
    }
}

#Preview("Planets") {
    let http = URLSessionHTTPClient()
    let svc = PlanetsServiceImpl(http: http)
    PlanetsView(vm: PlanetsViewModel(service: svc))
}
