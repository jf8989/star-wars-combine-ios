// View/Components/UnderlinedField.swift

import SwiftUI
import UIKit

/// Underlined text field that adapts to FieldState and Light/Dark mode.
/// - contentType is optional (pass nil when you don't want any).
struct UnderlinedField: View {
    let title: String
    @Binding var text: String
    let state: FieldState
    let contentType: UITextContentType?
    let keyboard: UIKeyboardType

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField(title, text: $text)
                .textInputAutocapitalization(.words)
                .textContentType(contentType)
                .keyboardType(keyboard)
                .autocorrectionDisabled()
                .padding(.vertical, 8)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(underlineColor(for: state))
                        .frame(height: 2)
                        .animation(.easeInOut(duration: 0.15), value: state)
                }

            if case .invalid(let message) = state {
                Text(message)   
                    .font(.footnote)
                    .foregroundStyle(.red)  // dynamic system red
            }
        }
    }

    private func underlineColor(for state: FieldState) -> Color {
        switch state {
        case .idle:
            return Color(UIColor.separator)  // dynamic, good contrast
        case .typing:
            return Color.accentColor  // respects current tint
        case .valid:
            return .green
        case .invalid:
            return .red
        }
    }
}
