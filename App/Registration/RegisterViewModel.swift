// App/Registration/RegisterViewModel.swift

import Combine
import Foundation

/// ViewModel for the Register screen.
/// - Holds raw field strings
/// - Maps them to FieldState via pure Model validators
/// - Exposes overall `isFormValid` and a navigation flag `shouldNavigateToPlanets`
@MainActor
public final class RegisterViewModel: ObservableObject {
    // Inputs
    @Published public var name: String = ""
    @Published public var lastName: String = ""
    @Published public var age: String = ""
    @Published public var phone: String = ""
    @Published public var email: String = ""
    @Published public var documentType: DocumentType = .id
    @Published public var documentNumber: String = ""

    // UI states
    @Published public private(set) var nameState: FieldState = .idle
    @Published public private(set) var lastNameState: FieldState = .idle
    @Published public private(set) var ageState: FieldState = .idle
    @Published public private(set) var phoneState: FieldState = .idle
    @Published public private(set) var emailState: FieldState = .idle
    @Published public private(set) var documentNumberState: FieldState = .idle

    // Form + navigation
    @Published public private(set) var isFormValid: Bool = false
    @Published public var shouldNavigateToPlanets: Bool = false

    private let bag = TaskBag()

    public init() {
        // Per-field states
        $name
            .map(Self.stateForName)
            .sink { [weak self] in self?.nameState = $0 }
            .store(in: bag)

        $lastName
            .map(Self.stateForLastName)
            .sink { [weak self] in self?.lastNameState = $0 }
            .store(in: bag)

        $age
            .map(Self.stateForAge)
            .sink { [weak self] in self?.ageState = $0 }
            .store(in: bag)

        $phone
            .map(Self.stateForPhone)
            .sink { [weak self] in self?.phoneState = $0 }
            .store(in: bag)

        $email
            .map(Self.stateForEmail)
            .sink { [weak self] in self?.emailState = $0 }
            .store(in: bag)

        Publishers.CombineLatest($documentNumber, $documentType)
            .map(Self.stateForDocument)
            .sink { [weak self] in self?.documentNumberState = $0 }
            .store(in: bag)

        // Overall form validity
        let nameValid = $name.map(RegisterValidation.validateName)
        let lastValid = $lastName.map(RegisterValidation.validateLastName)
        let ageValid = $age.map(RegisterValidation.validateAge)
        let phoneValid = $phone.map(RegisterValidation.validatePhone8Digits)
        let emailValid = $email.map(RegisterValidation.validateEmailBasic)
        let docValid = Publishers.CombineLatest($documentNumber, $documentType)
            .map { RegisterValidation.validateDocNumber($0.0, for: $0.1) }

        let a = Publishers.CombineLatest(nameValid, lastValid).map { $0 && $1 }
        let b = Publishers.CombineLatest(ageValid, phoneValid).map { $0 && $1 }
        let c = Publishers.CombineLatest(emailValid, docValid).map { $0 && $1 }

        Publishers.CombineLatest3(a, b, c)
            .map { $0 && $1 && $2 }
            .removeDuplicates()
            .sink { [weak self] in self?.isFormValid = $0 }
            .store(in: bag)
    }

    // MARK: - Intents
    public func signUp() {
        // View should observe this and reset it after navigating.
        if isFormValid { shouldNavigateToPlanets = true }
    }

    // MARK: - Helpers
    private static func stateForName(_ raw: String) -> FieldState {
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return .idle }
        return RegisterValidation.validateName(s)
            ? .valid : .invalid(message: "Enter at least 2 characters.")
    }

    private static func stateForLastName(_ raw: String) -> FieldState {
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return .idle }
        return RegisterValidation.validateLastName(s)
            ? .valid : .invalid(message: "Enter at least 2 characters.")
    }

    private static func stateForAge(_ raw: String) -> FieldState {
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return .idle }
        return RegisterValidation.validateAge(s)
            ? .valid : .invalid(message: "Age must be over 18.")
    }

    private static func stateForPhone(_ raw: String) -> FieldState {
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return .idle }
        return RegisterValidation.validatePhone8Digits(s)
            ? .valid : .invalid(message: "Phone must be 8 digits.")
    }

    private static func stateForEmail(_ raw: String) -> FieldState {
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return .idle }
        return RegisterValidation.validateEmailBasic(s)
            ? .valid : .invalid(message: "Enter a valid email.")
    }

    private static func stateForDocument(number: String, type: DocumentType)
        -> FieldState
    {
        let s = number.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return .idle }
        let ok = RegisterValidation.validateDocNumber(s, for: type)
        if ok { return .valid }
        switch type {
        case .id: return .invalid(message: "ID must be exactly 8 digits.")
        case .passport:
            return .invalid(
                message: "Passport: 1 letter + 8 letters/digits (9 total)."
            )
        }
    }
}
