import Foundation
import UIKit

protocol AIService {
    func generateRoasts(image: UIImage, config: RoastConfig) async throws -> [String]
}

enum AIServiceError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case apiError(String)
    case imageTooLarge
    case noRoastsGenerated

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:       return "API key is missing. Configure it in Settings."
        case .invalidResponse:     return "Received an unexpected response from the AI."
        case .apiError(let msg):   return "API error: \(msg)"
        case .imageTooLarge:       return "The image is too large. Please use a smaller photo."
        case .noRoastsGenerated:   return "No roasts were generated. Try again."
        }
    }
}

func makeAIService(config: AIConfig) -> AIService {
    switch config.provider {
    case .openAI:      return OpenAIService(config: config)
    case .anthropic:   return AnthropicService(config: config)
    case .gemini:      return GeminiService(config: config)
    case .openRouter:  return OpenRouterService(config: config)
    }
}

// MARK: - Shared prompt builder

func buildRoastPrompt(config: RoastConfig) -> String {
    """
    You are a ruthless AI roast comedian. Analyze this photo and generate exactly \(config.count) distinct roasts.

    Style: \(config.style.rawValue) — \(config.style.prompt)
    Intensity: \(config.intensityPercent)% (\(config.intensityLabel))

    Rules:
    - Focus on visible appearance, clothing, accessories, expression, body language
    - Each roast must be a standalone joke (1–3 sentences)
    - No repeating the same punchline
    - No racist, sexist, or hate-speech content
    - Return ONLY the roasts, one per line, no numbering, no extra text
    """
}
