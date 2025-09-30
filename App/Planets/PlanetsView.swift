// /App/Planets/PlanetsView.swift

import SwiftUI

struct PlanetsView: View {

    @StateObject private var planetsVM: PlanetsViewModel = {
        let http = URLSessionHTTPClient()
        let real = PlanetsServiceLive(http: http)  // network
        let service = LocalSearchPlanetsService(base: real, backfillAll: false)
        // backfillAll: false → honors single-call policy; no background page walking
        return PlanetsViewModel(service: service)
    }()

    var body: some View {
        PlanetsScreenView(viewModel: planetsVM)
    }
}

#Preview("Planets") {
    PlanetsView()
}
