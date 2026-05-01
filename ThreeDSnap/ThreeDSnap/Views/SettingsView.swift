import SwiftUI

struct SettingsView: View {
    @AppStorage("defaultUnit") private var defaultUnit: String = LengthUnit.feet.rawValue
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true
    @AppStorage("autoSave") private var autoSave: Bool = true

    var body: some View {
        NavigationStack {
            Form {
                Section("Units") {
                    Picker("Default unit", selection: $defaultUnit) {
                        ForEach(LengthUnit.allCases, id: \.self) { unit in
                            Text(unit.label).tag(unit.rawValue)
                        }
                    }
                }
                Section("Capture") {
                    Toggle("Haptic feedback", isOn: $hapticsEnabled)
                    Toggle("Auto-save scans", isOn: $autoSave)
                }
                Section("Export") {
                    NavigationLink("Export formats") {
                        ExportFormatsView()
                    }
                }
                Section("About") {
                    LabeledContent("Version", value: "1.0.0")
                    LabeledContent("Build", value: "100")
                    Link("Terms of Use", destination: URL(string: "https://example.com/terms")!)
                    Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                }
            }
            .navigationTitle("Settings")
            .scrollContentBackground(.hidden)
            .background(Color.black.ignoresSafeArea())
        }
    }
}

private struct ExportFormatsView: View {
    var body: some View {
        List {
            Section("Available formats") {
                ExportFormatRow(title: "PDF Floor Plan",
                                subtitle: "Send to contractors or print on paper",
                                icon: "doc.richtext.fill")
                ExportFormatRow(title: "USDZ 3D Model",
                                subtitle: "Open in Reality Composer or Quick Look",
                                icon: "cube.transparent.fill")
                ExportFormatRow(title: "PNG Image",
                                subtitle: "Share to messages or social",
                                icon: "photo.fill")
                ExportFormatRow(title: "OBJ + MTL",
                                subtitle: "Import into Blender or SketchUp",
                                icon: "shippingbox.fill")
            }
        }
        .navigationTitle("Export")
    }
}

private struct ExportFormatRow: View {
    let title: String
    let subtitle: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 32, height: 32)
                .background(.blue, in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(.white)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body.weight(.semibold))
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SettingsView()
}
