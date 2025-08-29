// Model/RegisterValidation.swift

import Foundation

/// Document types supported by the mock form (domain-only; no UI).
public enum DocumentType: String, CaseIterable {
    case id
    case passport
}

/// Pure validators for the Register screen. No UI, no Combine, no side effects.
/// VM maps these to FieldState and error messages.
public enum RegisterValidation {

    /// Non-empty name with at least 2 non-space characters.
    public static func validateName(_ raw: String) -> Bool {
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return s.count >= 2
    }

    /// Non-empty last name with at least 2 non-space characters.
    public static func validateLastName(_ raw: String) -> Bool {
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return s.count >= 2
    }

    /// Age must be an integer in [18, 120].
    public static func validateAge(_ raw: String) -> Bool {
        guard let age = Int(raw.trimmingCharacters(in: .whitespacesAndNewlines))
        else { return false }
        return (18...120).contains(age)
    }

    /// Exactly 8 digits (no spaces, no symbols).
    public static func validatePhone8Digits(_ raw: String) -> Bool {
        let digits = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard digits.count == 8 else { return false }
        return digits.allSatisfy(\.isNumber)
    }

    /// Basic email rule: something@something.tld (TLD length >= 2). Intentionally simple.
    public static func validateEmailBasic(_ raw: String) -> Bool {
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        // Quick-and-clean regex, not exhaustive (by design for the assignment).
        let pattern = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
        return
            (try? NSRegularExpression(
                pattern: pattern,
                options: [.caseInsensitive]
            ))?
            .firstMatch(
                in: s,
                range: NSRange(location: 0, length: s.utf16.count)
            ) != nil
    }

    /// Document number:
    /// - id: exactly 8 digits
    /// - passport: 6–9 alphanumerics (letters or digits)
    public static func validateDocNumber(_ raw: String, for type: DocumentType)
        -> Bool
    {
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        switch type {
        case .id:
            return s.count == 8 && s.allSatisfy(\.isNumber)
        case .passport:
            guard (6...9).contains(s.count) else { return false }
            return s.unicodeScalars.allSatisfy {
                CharacterSet.alphanumerics.contains($0)
            }
        }
    }
}
