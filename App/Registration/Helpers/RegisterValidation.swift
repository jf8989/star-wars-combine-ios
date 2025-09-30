// App/Registration/Helpers/RegisterValidation.swift

import Foundation

/// Document types supported by the mock form (domain-only; no UI).
public enum DocumentType: String, CaseIterable {
    case id
    case passport
}

public enum RegisterValidation {

    /// Non-empty name with at least 2 non-space characters.
    public static func validateName(_ raw: String) -> Bool {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= 2
    }

    /// Non-empty last name with at least 2 non-space characters.
    public static func validateLastName(_ raw: String) -> Bool {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= 2
    }

    /// Age must be an integer in [19, 100].
    public static func validateAge(_ raw: String) -> Bool {
        guard let parsedAge = Int(raw.trimmingCharacters(in: .whitespacesAndNewlines))
        else { return false }
        return (19...100).contains(parsedAge)  // older than 18
    }

    /// Exactly 8 digits (no spaces, no symbols).
    public static func validatePhone8Digits(_ raw: String) -> Bool {
        let digits = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard digits.count == 8 else { return false }
        return digits.allSatisfy(\.isNumber)
    }

    /// Basic email rule: something@something.tld (single-segment TLD, 2–24 letters).
    /// No consecutive dots; `.com` must be exactly "com" (rejects ".commm…").
    public static func validateEmailBasic(_ raw: String) -> Bool {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        // Cheap pre-check: forbid consecutive dots in local or domain parts.
        guard trimmed.contains("..") == false else { return false }

        // Quick-and-clean regex, still intentionally basic.
        // - Negative lookahead after the final dot prevents ".commm…"
        // - Single TLD segment only (by design for the assignment)
        let pattern = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.(?!com[A-Z])[A-Z]{2,24}$"#

        return (try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]))?
            .firstMatch(in: trimmed, range: NSRange(location: 0, length: trimmed.utf16.count)) != nil
    }

    /// Document number:
    /// - id: exactly 8 digits
    /// - passport: Exactly 9 chars, first must be a letter, remaining are letters or digits
    public static func validateDocNumber(_ raw: String, for type: DocumentType) -> Bool {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        switch type {
        case .id:
            return trimmed.count == 8 && trimmed.allSatisfy(\.isNumber)
        case .passport:
            guard trimmed.count == 9 else { return false }
            guard let firstCharacter = trimmed.first, firstCharacter.isLetter else {
                return false
            }
            return trimmed.dropFirst().unicodeScalars.allSatisfy {
                CharacterSet.alphanumerics.contains($0)
            }
        }
    }
}
