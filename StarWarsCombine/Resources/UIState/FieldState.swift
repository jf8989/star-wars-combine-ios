// App/Shared/UIState/FieldState.swift

import Foundation

/// Per-input UI state that the View binds to (colors/messages).
public enum FieldState: Equatable {
    case idle
    case valid
    case invalid(message: String)
}
