// App/Registration/RegisterView.swift

import SwiftUI

/// Real Register screen: 6 inputs, per-state underline colors, inline error on invalid,
/// proper keyboards/content types, and Sign Up enabled only when form is valid.
struct RegisterView: View {
    @ObservedObject var vm: RegisterViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                UnderlinedField(
                    title: "Name",
                    text: $vm.name,
                    state: vm.nameState,
                    contentType: .givenName,
                    keyboard: .default,
                    autocap: .words
                )

                UnderlinedField(
                    title: "Last name",
                    text: $vm.lastName,
                    state: vm.lastNameState,
                    contentType: .familyName,
                    keyboard: .default,
                    autocap: .words
                )

                UnderlinedField(
                    title: "Age",
                    text: $vm.age,
                    state: vm.ageState,
                    contentType: nil,
                    keyboard: .numberPad,
                    autocap: .never
                )

                UnderlinedField(
                    title: "Phone (8 digits)",
                    text: $vm.phone,
                    state: vm.phoneState,
                    contentType: .telephoneNumber,
                    keyboard: .numberPad,
                    autocap: .never
                )

                UnderlinedField(
                    title: "Email",
                    text: $vm.email,
                    state: vm.emailState,
                    contentType: .emailAddress,
                    keyboard: .emailAddress,
                    autocap: .never
                )

                DocumentSection(vm: vm)

                PrimaryButton(
                    title: "Sign Up → Planets",
                    isEnabled: vm.isFormValid
                ) {
                    vm.signUp()
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
    RegisterView(vm: RegisterViewModel())
}
