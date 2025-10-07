// StarWarsCombine/Module/Screens/RegistrationScreen/Components/DocumentSection.swift

import SwiftUI
import UIKit

/// Small section holding Document type + number field.
/// View-only concerns; uses UnderlinedField internally.
struct DocumentSectionView: View {
    @ObservedObject var viewModel: RegisterViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("Document type", selection: $viewModel.documentType) {
                Text("ID").tag(DocumentType.id)
                Text("Passport").tag(DocumentType.passport)
            }
            .pickerStyle(.segmented)

            UnderlinedFieldView(
                title: viewModel.documentType == .id
                    ? "Document number (8 digits)" : "Passport",
                text: $viewModel.documentNumber,
                state: viewModel.documentNumberState,
                contentType: nil,
                keyboard: viewModel.documentType == .id ? .numberPad : .asciiCapable,
                autocap: .never
            )
        }
    }
}
