// /StarWarsCombine/Module/Screens/PlanetsScreen/PlanetsView.swift

import SwiftUI

struct PlanetsView: View {

    @StateObject private var planetsVM: PlanetsViewModel = {
        let httpClient = URLSessionHTTPClient()
        let liveService = PlanetsServiceLive(http: httpClient)
        let decoratedService = PlanetsSearchDecorator(base: liveService)

        return PlanetsViewModel(service: decoratedService)
    }()

    var body: some View {
        PlanetsScreenView(viewModel: planetsVM)
    }
}

#Preview("Planets") {
    PlanetsView()
}
