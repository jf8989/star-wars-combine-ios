/// Path: StarWarsTests/RegistrationScreen/RegisterValidationTests.swift
/// Role: Validation rules for Register form

import XCTest

@testable import StarWarsCombine

final class RegisterValidationTests: XCTestCase {

    // Name / Last Name
    func testValidateName_TrimsAndRequiresTwoCharacters() {
        // Given: various name inputs including whitespace and short strings
        // When / Then: validateName enforces trim + min length of 2
        XCTAssertFalse(RegisterValidation.validateName(" "))
        XCTAssertFalse(RegisterValidation.validateName(" A"))
        XCTAssertTrue(RegisterValidation.validateName(" Al"))
        XCTAssertTrue(RegisterValidation.validateName("  Ana  "))
    }

    func testValidateLastName_TrimsAndRequiresTwoCharacters() {
        // Given: last-name inputs of different lengths/spacing
        // When / Then: validateLastName applies same trim + min length rules
        XCTAssertFalse(RegisterValidation.validateLastName(""))
        XCTAssertFalse(RegisterValidation.validateLastName(" x"))
        XCTAssertTrue(RegisterValidation.validateLastName(" Xu"))
    }

    // Age
    func testValidateAge_IsIntegerAndWithinRange() {
        // Given: age strings covering non-integer, boundary, and in-range cases
        // When / Then: validateAge requires integer 18...100 inclusive
        XCTAssertFalse(RegisterValidation.validateAge(" seventeen "))
        XCTAssertFalse(RegisterValidation.validateAge("17"))
        XCTAssertTrue(RegisterValidation.validateAge("18"))
        XCTAssertTrue(RegisterValidation.validateAge(" 42 "))
        XCTAssertTrue(RegisterValidation.validateAge("100"))
        XCTAssertFalse(RegisterValidation.validateAge("101"))
    }

    // Phone
    func testValidatePhone_ExactlyEightDigits() {
        // Given: phone inputs with wrong count, spaces, and non-digits
        // When / Then: validatePhone8Digits passes only exactly 8 digits
        XCTAssertFalse(RegisterValidation.validatePhone8Digits("1234567"))
        XCTAssertFalse(RegisterValidation.validatePhone8Digits("123456789"))
        XCTAssertFalse(RegisterValidation.validatePhone8Digits("1234 678"))
        XCTAssertFalse(RegisterValidation.validatePhone8Digits("1234567a"))
        XCTAssertTrue(RegisterValidation.validatePhone8Digits("12345678"))
    }

    // Email
    func testValidateEmail_BasicRules() {
        // Given: email strings with double dots, long TLD, invalid format, valid mixed-case
        // When / Then: validateEmailBasic rejects invalids, accepts valid addresses (case-insensitive)
        XCTAssertFalse(RegisterValidation.validateEmailBasic("a@b..com"))
        XCTAssertFalse(RegisterValidation.validateEmailBasic("a@b.commm"))
        XCTAssertFalse(RegisterValidation.validateEmailBasic("not-an-email"))
        XCTAssertTrue(RegisterValidation.validateEmailBasic("john.doe@example.org"))
        XCTAssertTrue(RegisterValidation.validateEmailBasic("UPPER@EXAMPLE.NET"))
    }

    // Document
    func testValidateDocNumber_ID_EightDigits() {
        // Given: candidate ID numbers varying in length/characters
        // When / Then: validateDocNumber(.id) requires exactly 8 digits
        XCTAssertFalse(RegisterValidation.validateDocNumber("1234567", for: .id))
        XCTAssertFalse(RegisterValidation.validateDocNumber("1234567a", for: .id))
        XCTAssertTrue(RegisterValidation.validateDocNumber("12345678", for: .id))
    }

    func testValidateDocNumber_Passport_FirstLetterThenEightAlnum() {
        // Given: passport numbers with wrong shapes and a valid one
        // When / Then: validateDocNumber(.passport) enforces 1 letter + 8 alphanumeric
        XCTAssertFalse(RegisterValidation.validateDocNumber("123456789", for: .passport))
        XCTAssertFalse(RegisterValidation.validateDocNumber("A234567@", for: .passport))
        XCTAssertFalse(RegisterValidation.validateDocNumber("A234567", for: .passport))
        XCTAssertTrue(RegisterValidation.validateDocNumber("A2345678Z", for: .passport))
    }
}
