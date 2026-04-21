import Foundation
import Combine

@MainActor
final class AppSettings: ObservableObject {
    @Published var defaultLanguageCode: String {
        didSet { UserDefaults.standard.set(defaultLanguageCode, forKey: Keys.defaultLanguage) }
    }
    @Published var autoTranscribe: Bool {
        didSet { UserDefaults.standard.set(autoTranscribe, forKey: Keys.autoTranscribe) }
    }
    @Published var generateSummaryOnSave: Bool {
        didSet { UserDefaults.standard.set(generateSummaryOnSave, forKey: Keys.generateSummary) }
    }

    private enum Keys {
        static let defaultLanguage = "settings.defaultLanguage"
        static let autoTranscribe = "settings.autoTranscribe"
        static let generateSummary = "settings.generateSummary"
    }

    init() {
        let defaults = UserDefaults.standard
        self.defaultLanguageCode = defaults.string(forKey: Keys.defaultLanguage) ?? "auto"
        self.autoTranscribe = defaults.object(forKey: Keys.autoTranscribe) as? Bool ?? true
        self.generateSummaryOnSave = defaults.object(forKey: Keys.generateSummary) as? Bool ?? true
    }
}
