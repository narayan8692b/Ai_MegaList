import Foundation
import UIKit

final class OpenAIService: AIService {
    private let config: AIConfig
    private let baseURL = "https://api.openai.com/v1/chat/completions"

    init(config: AIConfig) {
        self.config = config
    }

    func generateRoasts(image: UIImage, config roastConfig: RoastConfig) async throws -> [String] {
        guard config.isValid else { throw AIServiceError.missingAPIKey }

        guard let base64 = image.resizedForAPI()?.jpegData(compressionQuality: 0.8)?.base64EncodedString() else {
            throw AIServiceError.imageTooLarge
        }

        let body: [String: Any] = [
            "model": config.model,
            "max_tokens": 1024,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        ["type": "text", "text": buildRoastPrompt(config: roastConfig)],
                        ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(base64)", "detail": "low"]]
                    ]
                ]
            ]
        ]

        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateHTTPResponse(response, data: data)

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard
            let choices = json?["choices"] as? [[String: Any]],
            let message = choices.first?["message"] as? [String: Any],
            let content = message["content"] as? String
        else { throw AIServiceError.invalidResponse }

        return parseRoasts(from: content)
    }
}

// MARK: - Anthropic

final class AnthropicService: AIService {
    private let config: AIConfig
    private let baseURL = "https://api.anthropic.com/v1/messages"

    init(config: AIConfig) {
        self.config = config
    }

    func generateRoasts(image: UIImage, config roastConfig: RoastConfig) async throws -> [String] {
        guard config.isValid else { throw AIServiceError.missingAPIKey }

        guard let imageData = image.resizedForAPI()?.jpegData(compressionQuality: 0.8) else {
            throw AIServiceError.imageTooLarge
        }
        let base64 = imageData.base64EncodedString()

        let body: [String: Any] = [
            "model": config.model,
            "max_tokens": 1024,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        ["type": "image", "source": [
                            "type": "base64",
                            "media_type": "image/jpeg",
                            "data": base64
                        ]],
                        ["type": "text", "text": buildRoastPrompt(config: roastConfig)]
                    ]
                ]
            ]
        ]

        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue(config.apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateHTTPResponse(response, data: data)

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard
            let content = json?["content"] as? [[String: Any]],
            let text = content.first(where: { $0["type"] as? String == "text" })?["text"] as? String
        else { throw AIServiceError.invalidResponse }

        return parseRoasts(from: text)
    }
}

// MARK: - Gemini

final class GeminiService: AIService {
    private let config: AIConfig

    init(config: AIConfig) {
        self.config = config
    }

    private var baseURL: String {
        "https://generativelanguage.googleapis.com/v1beta/models/\(config.model):generateContent?key=\(config.apiKey)"
    }

    func generateRoasts(image: UIImage, config roastConfig: RoastConfig) async throws -> [String] {
        guard config.isValid else { throw AIServiceError.missingAPIKey }

        guard let imageData = image.resizedForAPI()?.jpegData(compressionQuality: 0.8) else {
            throw AIServiceError.imageTooLarge
        }
        let base64 = imageData.base64EncodedString()

        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": buildRoastPrompt(config: roastConfig)],
                        ["inline_data": ["mime_type": "image/jpeg", "data": base64]]
                    ]
                ]
            ],
            "generationConfig": ["maxOutputTokens": 1024]
        ]

        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateHTTPResponse(response, data: data)

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard
            let candidates = json?["candidates"] as? [[String: Any]],
            let content = candidates.first?["content"] as? [String: Any],
            let parts = content["parts"] as? [[String: Any]],
            let text = parts.first?["text"] as? String
        else { throw AIServiceError.invalidResponse }

        return parseRoasts(from: text)
    }
}

// MARK: - OpenRouter

final class OpenRouterService: AIService {
    private let config: AIConfig
    private let baseURL = "https://openrouter.ai/api/v1/chat/completions"

    init(config: AIConfig) {
        self.config = config
    }

    func generateRoasts(image: UIImage, config roastConfig: RoastConfig) async throws -> [String] {
        guard config.isValid else { throw AIServiceError.missingAPIKey }

        guard let base64 = image.resizedForAPI()?.jpegData(compressionQuality: 0.8)?.base64EncodedString() else {
            throw AIServiceError.imageTooLarge
        }

        let body: [String: Any] = [
            "model": config.model,
            "max_tokens": 1024,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        ["type": "text", "text": buildRoastPrompt(config: roastConfig)],
                        ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(base64)"]]
                    ]
                ]
            ]
        ]

        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("RoastBot iOS", forHTTPHeaderField: "X-Title")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateHTTPResponse(response, data: data)

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard
            let choices = json?["choices"] as? [[String: Any]],
            let message = choices.first?["message"] as? [String: Any],
            let content = message["content"] as? String
        else { throw AIServiceError.invalidResponse }

        return parseRoasts(from: content)
    }
}

// MARK: - Shared helpers

private func validateHTTPResponse(_ response: URLResponse, data: Data) throws {
    guard let http = response as? HTTPURLResponse else { return }
    guard (200...299).contains(http.statusCode) else {
        let msg = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])
            .flatMap { $0["error"] as? [String: Any] }
            .flatMap { $0["message"] as? String }
            ?? HTTPURLResponse.localizedString(forStatusCode: http.statusCode)
        throw AIServiceError.apiError("[\(http.statusCode)] \(msg)")
    }
}

private func parseRoasts(from text: String) throws -> [String] {
    let roasts = text
        .components(separatedBy: "\n")
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
    guard !roasts.isEmpty else { throw AIServiceError.noRoastsGenerated }
    return roasts
}
