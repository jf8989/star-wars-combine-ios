// App/Navigation/Router.swift
// Role Environment-scoped navigation source of truth (push/pop/reset)

import SwiftUI

/// Centralizes Navigation path so features can push/pop without coupling
/// business logic to UI concerns.
final class Router: ObservableObject {
    @Published var path: [AppRoutes] = []

    func push(_ route: AppRoutes) {
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    /// Reset the stack (useful for deep links or logout flows).
    func reset(to newPath: [AppRoutes] = []) {
        path = newPath
    }
}
