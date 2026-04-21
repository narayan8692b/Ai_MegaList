import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    @State private var showLanguagePicker = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                Form {
                    Section {
                        Button {
                            showLanguagePicker = true
                        } label: {
                            HStack {
                                Label("Default language", systemImage: "globe")
                                    .foregroundColor(Theme.textPrimary)
                                Spacer()
                                Text(Languages.named(settings.defaultLanguageCode).name)
                                    .foregroundColor(Theme.textSecondary)
                                Image(systemName: "chevron.right")
                                    .foregroundColor(Theme.textTertiary)
                                    .font(.caption)
                            }
                        }
                    } header: {
                        Text("Transcription")
                    }
                    .listRowBackground(Theme.card)

                    Section {
                        Toggle(isOn: $settings.autoTranscribe) {
                            Label("Auto-transcribe after recording", systemImage: "waveform")
                        }
                        .foregroundColor(Theme.textPrimary)
                        Toggle(isOn: $settings.generateSummaryOnSave) {
                            Label("Generate summary & flash cards", systemImage: "sparkles")
                        }
                        .foregroundColor(Theme.textPrimary)
                    } header: {
                        Text("AI Processing")
                    }
                    .listRowBackground(Theme.card)

                    Section {
                        Label("Version 1.0.0", systemImage: "info.circle")
                            .foregroundColor(Theme.textSecondary)
                    } header: {
                        Text("About")
                    }
                    .listRowBackground(Theme.card)
                }
                .scrollContentBackground(.hidden)
                .tint(Theme.accent)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(Theme.textPrimary)
                    }
                }
            }
            .sheet(isPresented: $showLanguagePicker) {
                LanguagePickerView(selectedCode: settings.defaultLanguageCode) { newCode in
                    settings.defaultLanguageCode = newCode
                }
            }
        }
    }
}
