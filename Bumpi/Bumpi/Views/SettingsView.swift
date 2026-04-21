import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var profileStore: BabyProfileStore
    @EnvironmentObject var recordingStore: RecordingStore
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var dueDate: Date = Date()
    @State private var showResetAlert = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Baby") {
                    TextField("Name", text: $name)
                    DatePicker("Due date", selection: $dueDate, displayedComponents: .date)
                }

                Section("Recordings") {
                    HStack {
                        Text("Saved recordings")
                        Spacer()
                        Text("\(recordingStore.recordings.count)")
                            .foregroundColor(.secondary)
                    }
                }

                Section("About") {
                    Label("Bumpi is not a medical device", systemImage: "exclamationmark.shield.fill")
                        .foregroundColor(BumpiTheme.primary)
                    Text("Bumpi uses your phone's microphone for bonding and comfort. It does not replace professional prenatal care. Consult your doctor or midwife for medical questions.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                Section {
                    Button(role: .destructive) {
                        showResetAlert = true
                    } label: {
                        Label("Reset profile", systemImage: "arrow.counterclockwise")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear(perform: load)
            .alert("Reset profile?", isPresented: $showResetAlert) {
                Button("Reset", role: .destructive) {
                    profileStore.clear()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This clears your baby's name and due date. Your recordings are kept.")
            }
        }
    }

    private func load() {
        guard let profile = profileStore.profile else { return }
        name = profile.name
        dueDate = profile.dueDate
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        profileStore.update(name: trimmed, dueDate: dueDate)
    }
}
