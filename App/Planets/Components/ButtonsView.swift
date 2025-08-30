// App/Main/Components/Buttons.swift

import SwiftUI

/// Reusable primary button used by RegisterView.
struct PrimaryButtonView: View {
    let title: String
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(title) { action() }
            .buttonStyle(.borderedProminent)
            .disabled(!isEnabled)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}
