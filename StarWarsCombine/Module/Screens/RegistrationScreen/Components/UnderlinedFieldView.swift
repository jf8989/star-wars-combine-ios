// StarWarsCombine/Module/Screens/RegistrationScreen/Components/UnderlinedField.swift

import SwiftUI
import UIKit

struct UnderlinedFieldView: View {

    let title: String
    @Binding var text: String
    let state: FieldState
    let contentType: UITextContentType?
    let keyboard: UIKeyboardType
    let autocap: TextInputAutocapitalization

    @FocusState private var isFocused: Bool

    init(
        title: String,
        text: Binding<String>,
        state: FieldState,
        contentType: UITextContentType?,
        keyboard: UIKeyboardType,
        autocap: TextInputAutocapitalization = .words
    ) {
        self.title = title
        self._text = text
        self.state = state
        self.contentType = contentType
        self.keyboard = keyboard
        self.autocap = autocap
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {

            TextField(title, text: $text)
                .textInputAutocapitalization(autocap)
                .textContentType(contentType)
                .keyboardType(keyboard)
                .autocorrectionDisabled()
                .focused($isFocused)
                .id(keyboard.rawValue)  // Force a fresh UITextField when keyboard type changes
                .padding(.vertical, 8)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(underlineColor())
                        .frame(height: 2)
                        .animation(.easeInOut(duration: 0.15), value: state)
                        .animation(.easeInOut(duration: 0.15), value: isFocused)
                }

            if case .invalid(let message) = state {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.red)  // dynamic system red
            }
        }
        .onChange(of: keyboard) {
            // If the user is typing, briefly drop and restore focus to apply the new keyboard
            if isFocused {
                isFocused = false
                DispatchQueue.main.async { isFocused = true }
            }
        }
    }

    private func underlineColor() -> Color {
        switch state {
        case .invalid:
            return .red
        case .valid:
            return .green
        default:
            // Focused while not invalid => blue (accent). Otherwise system separator.
            return isFocused ? Color.accentColor : Color(UIColor.separator)
        }
    }
}
