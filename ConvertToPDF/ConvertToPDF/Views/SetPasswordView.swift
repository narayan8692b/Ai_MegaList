import SwiftUI

struct SetPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    let document: PDFDocumentItem
    var onUpdate: (PDFDocumentItem) -> Void

    @State private var password = ""
    @State private var confirm = ""
    @State private var errorMessage: String?
    @State private var isWorking = false

    var body: some View {
        NavigationStack {
            Form {
                Section("New password") {
                    SecureField("Password", text: $password)
                    SecureField("Confirm password", text: $confirm)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }

                Section {
                    Button {
                        apply()
                    } label: {
                        if isWorking {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text(document.isPasswordProtected ? "Update Password" : "Set Password")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(password.isEmpty || password != confirm || isWorking)

                    if document.isPasswordProtected {
                        Button(role: .destructive) {
                            remove()
                        } label: {
                            Text("Remove Password")
                                .frame(maxWidth: .infinity)
                        }
                        .disabled(password.isEmpty || isWorking)
                    }
                }
            }
            .navigationTitle(document.isPasswordProtected ? "Change Password" : "Set Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func apply() {
        guard password == confirm else {
            errorMessage = "Passwords don't match."
            return
        }
        guard password.count >= 4 else {
            errorMessage = "Use at least 4 characters."
            return
        }
        isWorking = true
        errorMessage = nil
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try PDFManager.setPassword(password, on: document)
                DispatchQueue.main.async {
                    isWorking = false
                    var updated = document
                    updated.isPasswordProtected = true
                    onUpdate(updated)
                    dismiss()
                }
            } catch {
                DispatchQueue.main.async {
                    isWorking = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func remove() {
        isWorking = true
        errorMessage = nil
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try PDFManager.removePassword(from: document, password: password)
                DispatchQueue.main.async {
                    isWorking = false
                    var updated = document
                    updated.isPasswordProtected = false
                    onUpdate(updated)
                    dismiss()
                }
            } catch {
                DispatchQueue.main.async {
                    isWorking = false
                    errorMessage = "Couldn't unlock with that password."
                }
            }
        }
    }
}
