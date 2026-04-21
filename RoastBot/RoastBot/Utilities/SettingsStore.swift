import Foundation
import Combine

final class SettingsStore: ObservableObject {
    @Published var selectedProvider: AIProvider {
        didSet {
            UserDefaults.standard.set(selectedProvider.rawValue, forKey: Keys.provider)
            selectedModel = selectedProvider.defaultModel
        }
    }

    @Published var selectedModel: String {
        didSet { UserDefaults.standard.set(selectedModel, forKey: Keys.model) }
    }

    @Published var apiKey: String = "" {
        didSet { KeychainHelper.save(apiKey, for: keychainKey) }
    }

    private var keychainKey: String { "roastbot_apikey_\(selectedProvider.rawValue)" }

    init() {
        let providerRaw = UserDefaults.standard.string(forKey: Keys.provider) ?? AIProvider.openAI.rawValue
        let provider = AIProvider(rawValue: providerRaw) ?? .openAI
        selectedProvider = provider
        selectedModel = UserDefaults.standard.string(forKey: Keys.model) ?? provider.defaultModel
        apiKey = KeychainHelper.load(for: "roastbot_apikey_\(provider.rawValue)") ?? ""
    }

    func loadKeyForCurrentProvider() {
        apiKey = KeychainHelper.load(for: keychainKey) ?? ""
    }

    var aiConfig: AIConfig {
        AIConfig(provider: selectedProvider, apiKey: apiKey, model: selectedModel)
    }

    private enum Keys {
        static let provider = "roastbot_provider"
        static let model    = "roastbot_model"
    }
}
