// App/Registration/RegisterViewModel.swift

import Combine
import Foundation

public final class RegisterViewModel: ObservableObject {
    // Inputs
    @Published var name: String = ""
    @Published var lastName: String = ""
    @Published var age: String = ""
    @Published var phone: String = ""
    @Published var email: String = ""
    @Published var documentType: DocumentType = .id
    @Published var documentNumber: String = ""

    // UI states
    @Published private(set) var nameState: FieldState = .idle
    @Published private(set) var lastNameState: FieldState = .idle
    @Published private(set) var ageState: FieldState = .idle
    @Published private(set) var phoneState: FieldState = .idle
    @Published private(set) var emailState: FieldState = .idle
    @Published private(set) var documentNumberState: FieldState = .idle

    // Form validity
    @Published private(set) var isFormValid: Bool = false

    private let bag = TaskBag()

    init() {
        // Per-field states
        $name.map(stateForName).sink { [weak self] in self?.nameState = $0 }.store(in: bag)
        $lastName.map(stateForLastName).sink { [weak self] in self?.lastNameState = $0 }.store(in: bag)
        $age.map(stateForAge).sink { [weak self] in self?.ageState = $0 }.store(in: bag)
        $phone.map(stateForPhone).sink { [weak self] in self?.phoneState = $0 }.store(in: bag)
        $email.map(stateForEmail).sink { [weak self] in self?.emailState = $0 }.store(in: bag)

        Publishers.CombineLatest($documentNumber, $documentType)
            .map(stateForDocument)
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
    public func signUp() {}
}

// MARK: - Validation Helpers Ext.
extension RegisterViewModel {

    private func stateForName(_ raw: String) -> FieldState {
        let trimmedStr = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedStr.isEmpty else { return .idle }
        return RegisterValidation.validateName(trimmedStr) ? .valid : .invalid(message: "Enter at least 2 characters.")
    }

    private func stateForLastName(_ raw: String) -> FieldState {
        let trimmedStr = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedStr.isEmpty else { return .idle }
        return RegisterValidation.validateLastName(trimmedStr)
            ? .valid : .invalid(message: "Enter at least 2 characters.")
    }

    private func stateForAge(_ raw: String) -> FieldState {
        let trimmedStr = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedStr.isEmpty else { return .idle }
        return RegisterValidation.validateAge(trimmedStr) ? .valid : .invalid(message: "Age must be 18 or older.")
    }

    private func stateForPhone(_ raw: String) -> FieldState {
        let trimmedStr = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedStr.isEmpty else { return .idle }
        return RegisterValidation.validatePhone8Digits(trimmedStr)
            ? .valid : .invalid(message: "Phone must be 8 digits.")
    }

    private func stateForEmail(_ raw: String) -> FieldState {
        let trimmedStr = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedStr.isEmpty else { return .idle }
        return RegisterValidation.validateEmailBasic(trimmedStr) ? .valid : .invalid(message: "Enter a valid email.")
    }

    private func stateForDocument(number: String, type: DocumentType) -> FieldState {
        let trimmedStr = number.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedStr.isEmpty else { return .idle }
        let ok = RegisterValidation.validateDocNumber(trimmedStr, for: type)
        if ok { return .valid }
        switch type {
        case .id: return .invalid(message: "ID must be exactly 8 digits.")
        case .passport:
            return .invalid(message: "Passport: 1 letter + 8 letters/digits (9 total).")
        }
    }
}
