import SwiftUI

struct RenameDocumentView: View {
    @Environment(\.dismiss) private var dismiss
    let currentName: String
    var onRename: (String) -> Void

    @State private var name: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextField("Document name", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .padding(.top)

                Button("Save") {
                    let trimmed = name.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty else { return }
                    onRename(trimmed)
                    dismiss()
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)

                Spacer()
            }
            .padding()
            .navigationTitle("Rename Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear { name = currentName }
        }
    }
}
