// App/Registration/RegisterView.swift

import SwiftUI

/// Real Register screen: 6 inputs, per-state underline colors, inline error on invalid,
/// proper keyboards/content types, and Sign Up enabled only when form is valid.
struct RegisterView: View {
    @EnvironmentObject private var router: Router
    @StateObject var registerVM: RegisterViewModel = RegisterViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                UnderlinedFieldView(
                    title: "Name",
                    text: $registerVM.name,
                    state: registerVM.nameState,
                    contentType: .givenName,
                    keyboard: .default,
                    autocap: .words
                )
                UnderlinedFieldView(
                    title: "Last name",
                    text: $registerVM.lastName,
                    state: registerVM.lastNameState,
                    contentType: .familyName,
                    keyboard: .default,
                    autocap: .words
                )
                UnderlinedFieldView(
                    title: "Age",
                    text: $registerVM.age,
                    state: registerVM.ageState,
                    contentType: nil,
                    keyboard: .numberPad,
                    autocap: .never
                )
                UnderlinedFieldView(
                    title: "Phone (8 digits)",
                    text: $registerVM.phone,
                    state: registerVM.phoneState,
                    contentType: .telephoneNumber,
                    keyboard: .numberPad,
                    autocap: .never
                )
                UnderlinedFieldView(
                    title: "Email",
                    text: $registerVM.email,
                    state: registerVM.emailState,
                    contentType: .emailAddress,
                    keyboard: .emailAddress,
                    autocap: .never
                )

                DocumentSectionView(vm: registerVM)

                PrimaryButtonView(
                    title: "Sign Up → Planets",
                    isEnabled: registerVM.isFormValid
                ) {
                    registerVM.signUp()
                    if registerVM.isFormValid {
                        router.push(.planets)
                    }
                }
                .padding(.top, 6)
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .navigationTitle("Register")
    }
}

#Preview("Register") {
    RegisterView(registerVM: RegisterViewModel())
        .environmentObject(Router())
}
