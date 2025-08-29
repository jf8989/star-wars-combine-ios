// View/Components/PrimaryButton.swift

import SwiftUI

/// Reusable primary button used by RegisterView.
struct PrimaryButton: View {
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
