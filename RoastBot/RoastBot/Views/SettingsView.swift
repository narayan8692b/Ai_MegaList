import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsStore: SettingsStore
    @Environment(\.dismiss) private var dismiss
    @State private var showKey = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                Form {
                    Section {
                        Picker("Provider", selection: $settingsStore.selectedProvider) {
                            ForEach(AIProvider.allCases) { provider in
                                Text(provider.rawValue).tag(provider)
                            }
                        }
                        .onChange(of: settingsStore.selectedProvider) { _, _ in
                            settingsStore.loadKeyForCurrentProvider()
                        }

                        Picker("Model", selection: $settingsStore.selectedModel) {
                            ForEach(settingsStore.selectedProvider.models, id: \.self) { model in
                                Text(model).tag(model)
                            }
                        }
                    } header: {
                        Text("AI Provider")
                    }

                    Section {
                        HStack {
                            Group {
                                if showKey {
                                    TextField(settingsStore.selectedProvider.apiKeyPlaceholder, text: $settingsStore.apiKey)
                                } else {
                                    SecureField(settingsStore.selectedProvider.apiKeyPlaceholder, text: $settingsStore.apiKey)
                                }
                            }
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .font(.system(.body, design: .monospaced))

                            Button {
                                showKey.toggle()
                            } label: {
                                Image(systemName: showKey ? "eye.slash" : "eye")
                                    .foregroundColor(.gray)
                            }
                        }

                        if !settingsStore.apiKey.isEmpty {
                            Button(role: .destructive) {
                                settingsStore.apiKey = ""
                                KeychainHelper.delete(for: "roastbot_apikey_\(settingsStore.selectedProvider.rawValue)")
                            } label: {
                                Label("Clear API Key", systemImage: "trash")
                            }
                        }
                    } header: {
                        Text("API Key")
                    } footer: {
                        Text("Your key is stored securely in the iOS Keychain and never leaves your device.")
                    }

                    Section {
                        ProviderInfoRow(provider: settingsStore.selectedProvider)
                    } header: {
                        Text("Where to get a key")
                    }

                    Section {
                        HStack {
                            Circle()
                                .fill(settingsStore.aiConfig.isValid ? Color.green : Color.red)
                                .frame(width: 10, height: 10)
                            Text(settingsStore.aiConfig.isValid ? "Ready to roast" : "API key required")
                                .foregroundColor(settingsStore.aiConfig.isValid ? .green : .red)
                        }
                    } header: {
                        Text("Status")
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color.black)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct ProviderInfoRow: View {
    let provider: AIProvider

    var infoText: String {
        switch provider {
        case .openAI:
            return "Get your key at platform.openai.com → API Keys"
        case .anthropic:
            return "Get your key at console.anthropic.com → API Keys"
        case .gemini:
            return "Get your key at aistudio.google.com → Get API Key"
        case .openRouter:
            return "Get your key at openrouter.ai → Keys (supports many models)"
        }
    }

    var body: some View {
        Text(infoText)
            .font(.subheadline)
            .foregroundColor(.secondary)
    }
}
