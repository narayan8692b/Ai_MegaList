import Foundation

struct Recording: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var createdAt: Date
    var duration: TimeInterval
    var audioFileName: String
    var languageCode: String
    var transcription: String
    var summary: String
    var bulletPoints: [String]
    var flashCards: [FlashCard]
    var quiz: [QuizQuestion]

    init(
        id: UUID = UUID(),
        title: String,
        createdAt: Date = Date(),
        duration: TimeInterval,
        audioFileName: String,
        languageCode: String = "auto",
        transcription: String = "",
        summary: String = "",
        bulletPoints: [String] = [],
        flashCards: [FlashCard] = [],
        quiz: [QuizQuestion] = []
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.duration = duration
        self.audioFileName = audioFileName
        self.languageCode = languageCode
        self.transcription = transcription
        self.summary = summary
        self.bulletPoints = bulletPoints
        self.flashCards = flashCards
        self.quiz = quiz
    }

    var formattedDuration: String {
        let totalSeconds = Int(duration.rounded())
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var formattedCreatedAt: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy h:mm a"
        return formatter.string(from: createdAt)
    }

    var preview: String {
        let trimmed = transcription.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "Tap to view details" }
        return String(trimmed.prefix(180))
    }
}
