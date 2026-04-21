import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: DocumentStore

    var body: some View {
        List {
            Section {
                LabeledContent("Documents", value: "\(store.documents.count)")
                LabeledContent("Total size", value: totalSize)
            }
            Section("About") {
                LabeledContent("Version", value: appVersion)
                LabeledContent("Build", value: appBuild)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var totalSize: String {
        let bytes = store.documents.reduce(Int64(0)) { $0 + $1.fileSize }
        let f = ByteCountFormatter()
        f.allowedUnits = [.useKB, .useMB, .useGB]
        f.countStyle = .file
        return f.string(fromByteCount: bytes)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var appBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}
