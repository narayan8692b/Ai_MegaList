import Foundation

enum AIProvider: String, CaseIterable, Identifiable, Codable {
    case openAI = "OpenAI"
    case anthropic = "Anthropic"
    case gemini = "Google Gemini"
    case openRouter = "OpenRouter"

    var id: String { rawValue }

    var models: [String] {
        switch self {
        case .openAI:
            return ["gpt-4o", "gpt-4o-mini", "gpt-4-turbo"]
        case .anthropic:
            return ["claude-opus-4-7", "claude-sonnet-4-6", "claude-haiku-4-5-20251001"]
        case .gemini:
            return ["gemini-2.0-flash", "gemini-1.5-pro", "gemini-1.5-flash"]
        case .openRouter:
            return ["openai/gpt-4o", "anthropic/claude-3.5-sonnet", "google/gemini-pro-vision"]
        }
    }

    var defaultModel: String { models[0] }

    var apiKeyPlaceholder: String {
        switch self {
        case .openAI:      return "sk-..."
        case .anthropic:   return "sk-ant-..."
        case .gemini:      return "AIza..."
        case .openRouter:  return "sk-or-..."
        }
    }

    var supportsVision: Bool { true }
}

struct AIConfig {
    var provider: AIProvider
    var apiKey: String
    var model: String

    var isValid: Bool { !apiKey.trimmingCharacters(in: .whitespaces).isEmpty }
}
