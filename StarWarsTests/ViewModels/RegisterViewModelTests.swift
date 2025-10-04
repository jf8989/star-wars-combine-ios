/// Path: StarWarsTests/ViewModels/RegisterViewModelTests.swift
/// Role: Drive RegisterViewModel inputs to test FieldStates + isFormValid

import Combine
import XCTest

@testable import StarWarsCombine

final class RegisterViewModelTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    func testAllFieldsValidMakesFormValid() {
        // Given a fresh RegisterViewModel
        let viewModel = RegisterViewModel()

        // And a subscriber waiting for the first 'true'
        let expectFormValidTrue = expectation(description: "form valid")
        viewModel.$isFormValid
            .filter { $0 }
            .prefix(1)
            .sink { _ in expectFormValidTrue.fulfill() }
            .store(in: &cancellables)

        // When all inputs are valid
        viewModel.name = "Ana"
        viewModel.lastName = "Doe"
        viewModel.age = "30"
        viewModel.phone = "12345678"
        viewModel.email = "ana@example.com"
        viewModel.documentType = .id
        viewModel.documentNumber = "12345678"

        // Then the form becomes valid
        wait(for: [expectFormValidTrue], timeout: 1.0)
    }

    func testInvalidatesWhenFieldRegresses() {
        // Given a model that is currently valid
        let viewModel = RegisterViewModel()
        viewModel.name = "Ana"
        viewModel.lastName = "Doe"
        viewModel.age = "30"
        viewModel.phone = "12345678"
        viewModel.email = "ana@example.com"
        viewModel.documentType = .id
        viewModel.documentNumber = "12345678"

        // And a subscriber expecting it to become invalid
        let expectFormBecomesInvalid = expectation(description: "form becomes invalid")
        viewModel.$isFormValid
            .dropFirst()
            .sink { isValid in
                if !isValid { expectFormBecomesInvalid.fulfill() }
            }
            .store(in: &cancellables)

        // When one field regresses to an invalid value
        viewModel.phone = "123"  // invalid phone

        // Then the form validity flips to false
        wait(for: [expectFormBecomesInvalid], timeout: 1.0)
    }

    func testFieldStatesUpdateCorrectly() {
        // Given a fresh RegisterViewModel
        let viewModel = RegisterViewModel()

        // When the name is blank (only whitespace)
        viewModel.name = " "
        // Then state is idle
        XCTAssertEqual(viewModel.nameState, .idle)

        // When the name is too short
        viewModel.name = "A"
        // Then state is invalid with message
        XCTAssertEqual(viewModel.nameState, .invalid(message: "Enter at least 2 characters."))

        // When the name becomes valid
        viewModel.name = "Ana"
        // Then state is valid
        XCTAssertEqual(viewModel.nameState, .valid)
    }

    func testDocumentValidationSwitchesByType() {
        // Given a fresh RegisterViewModel
        let viewModel = RegisterViewModel()

        // When type is ID with wrong length
        viewModel.documentType = .id
        viewModel.documentNumber = "1234567"
        // Then ID rule error is shown
        XCTAssertEqual(viewModel.documentNumberState, .invalid(message: "ID must be exactly 8 digits."))

        // When type switches to Passport with wrong format
        viewModel.documentType = .passport
        viewModel.documentNumber = "123456789"
        // Then passport rule error is shown
        XCTAssertEqual(
            viewModel.documentNumberState,
            .invalid(message: "Passport: 1 letter + 8 letters/digits (9 total).")
        )
    }
}
