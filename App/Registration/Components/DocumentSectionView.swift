// App/Registration/Components/DocumentSection.swift

import SwiftUI
import UIKit

/// Small section holding Document type + number field.
/// View-only concerns; uses UnderlinedField internally.
struct DocumentSectionView: View {
    @ObservedObject var vm: RegisterViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("Document type", selection: $vm.documentType) {
                Text("ID").tag(DocumentType.id)
                Text("Passport").tag(DocumentType.passport)
            }
            .pickerStyle(.segmented)

            UnderlinedField(
                title: vm.documentType == .id
                    ? "Document number (8 digits)" : "Passport",
                text: $vm.documentNumber,
                state: vm.documentNumberState,
                contentType: nil,
                keyboard: vm.documentType == .id ? .numberPad : .asciiCapable,
                autocap: .never
            )
        }
    }
}
