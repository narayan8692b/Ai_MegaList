import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var storage: DesignStorage

    var body: some View {
        NavigationStack {
            List {
                Section("About") {
                    LabeledRow(title: "App", value: "Ruum")
                    LabeledRow(title: "Version", value: "1.0.0")
                }

                Section("Library") {
                    LabeledRow(title: "Saved designs", value: "\(storage.designs.count)")
                }

                Section("Generation") {
                    Text("Ruum ships with an on-device preview generator. Plug in your Replicate / OpenAI / Stability key in AIDesignService to use a real model.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                Section("Support") {
                    Link("Website", destination: URL(string: "https://example.com")!)
                    Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                }
            }
            .navigationTitle("Settings")
        }
    }
}

private struct LabeledRow: View {
    let title: String
    let value: String
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value).foregroundColor(.secondary)
        }
    }
}
