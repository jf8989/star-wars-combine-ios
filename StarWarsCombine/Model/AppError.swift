// StarWarsCombine/Model/AppError.swift

import Foundation

/// Lightweight error taxonomy. VM maps this to alerts for the user.
public enum AppError: Error {
    case network(URLError)
    case decode(Error)
    case http(status: Int)
    case message(String)
}

extension AppError {
    /// Stable, user-facing string. Keep short and neutral.
    public var userMessage: String {
        switch self {
        case .network:
            return "Network connection appears to be offline."
        case .decode:
            return "We couldn't read the server response."
        case .http(let status):
            return "Server responded with status \(status)."
        case .message(let text):
            return text
        }
    }
}
