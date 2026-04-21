import Foundation

/// On-device text analysis that produces a summary, bullet points, flash cards, and quiz questions
/// from a transcribed recording. No external API calls - uses lightweight heuristics so the app works
/// fully offline. Swap the internals for a Claude API call if a key is configured in `AppSettings`.
final class AIService {
    static let shared = AIService()
    private init() {}

    struct Analysis {
        let summary: String
        let bulletPoints: [String]
        let flashCards: [FlashCard]
        let quiz: [QuizQuestion]
    }

    func analyze(transcription: String) -> Analysis {
        let cleaned = transcription.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else {
            return Analysis(summary: "", bulletPoints: [], flashCards: [], quiz: [])
        }

        let sentences = splitSentences(cleaned)
        let summary = buildSummary(sentences: sentences)
        let bullets = buildBulletPoints(sentences: sentences)
        let cards = buildFlashCards(sentences: sentences)
        let quiz = buildQuiz(sentences: sentences, bulletPoints: bullets)

        return Analysis(summary: summary, bulletPoints: bullets, flashCards: cards, quiz: quiz)
    }

    // MARK: - Sentence tokenisation

    private func splitSentences(_ text: String) -> [String] {
        var results: [String] = []
        text.enumerateSubstrings(in: text.startIndex..<text.endIndex, options: .bySentences) { sub, _, _, _ in
            if let s = sub?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty {
                results.append(s)
            }
        }
        if results.isEmpty {
            results = text
                .components(separatedBy: CharacterSet(charactersIn: ".!?\n"))
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }
        return results
    }

    private func tokens(_ sentence: String) -> [String] {
        sentence
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count > 3 && !Self.stopWords.contains($0) }
    }

    // MARK: - Summary

    private func buildSummary(sentences: [String]) -> String {
        guard !sentences.isEmpty else { return "" }

        var wordFrequency: [String: Int] = [:]
        for sentence in sentences {
            for token in tokens(sentence) {
                wordFrequency[token, default: 0] += 1
            }
        }

        let scored = sentences.enumerated().map { idx, sentence -> (Int, String, Double) in
            let toks = tokens(sentence)
            let score = toks.reduce(0.0) { $0 + Double(wordFrequency[$1] ?? 0) }
            let normalized = toks.isEmpty ? 0 : score / Double(toks.count)
            return (idx, sentence, normalized)
        }

        let targetCount = max(2, min(5, sentences.count / 3))
        let top = scored
            .sorted(by: { $0.2 > $1.2 })
            .prefix(targetCount)
            .sorted(by: { $0.0 < $1.0 })
            .map { $0.1 }

        return top.joined(separator: " ")
    }

    // MARK: - Bullet points

    private func buildBulletPoints(sentences: [String]) -> [String] {
        guard !sentences.isEmpty else { return [] }
        let count = min(8, max(3, sentences.count / 2))
        var picks: [String] = []
        let step = max(1, sentences.count / count)
        var idx = 0
        while idx < sentences.count && picks.count < count {
            let trimmed = sentences[idx].trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.count > 20 {
                picks.append(trimmed)
            }
            idx += step
        }
        if picks.isEmpty { picks = Array(sentences.prefix(3)) }
        return picks
    }

    // MARK: - Flash cards

    private func buildFlashCards(sentences: [String]) -> [FlashCard] {
        let candidates = sentences.filter { $0.count > 30 }.prefix(6)
        return candidates.map { sentence in
            let keyword = extractKeyword(from: sentence) ?? "this concept"
            let question = "What does the text say about \(keyword)?"
            return FlashCard(question: question, answer: sentence)
        }
    }

    private func extractKeyword(from sentence: String) -> String? {
        let words = sentence
            .components(separatedBy: CharacterSet.whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { word in
                guard word.count > 4, !Self.stopWords.contains(word.lowercased()) else { return false }
                return word.first?.isLetter ?? false
            }
        return words.max(by: { $0.count < $1.count })
    }

    // MARK: - Quiz

    private func buildQuiz(sentences: [String], bulletPoints: [String]) -> [QuizQuestion] {
        let base = bulletPoints.isEmpty ? Array(sentences.prefix(4)) : bulletPoints
        guard !base.isEmpty else { return [] }

        let distractorPool: [String] = [
            "The history of mathematics",
            "The physics of shooting",
            "How to create a radio show",
            "A debate about modern art",
            "The process of baking bread",
            "The geography of ancient Rome",
            "An introduction to economics",
            "The principles of marketing"
        ]

        return base.prefix(5).enumerated().map { idx, correct in
            let correctTrimmed = correct.trimmingCharacters(in: .whitespacesAndNewlines)
            var options = [correctTrimmed]
            var pool = distractorPool
            pool.shuffle()
            for item in pool where options.count < 4 {
                if !options.contains(item) { options.append(item) }
            }
            options.shuffle()
            let correctIdx = options.firstIndex(of: correctTrimmed) ?? 0
            return QuizQuestion(
                question: "Which statement best reflects point \(idx + 1) in the recording?",
                options: options,
                correctIndex: correctIdx
            )
        }
    }

    // MARK: - Stop words

    private static let stopWords: Set<String> = [
        "the", "and", "for", "that", "this", "with", "from", "have", "has", "had",
        "are", "was", "were", "been", "being", "which", "what", "when", "where",
        "there", "their", "they", "them", "then", "than", "into", "also", "about",
        "some", "such", "just", "more", "most", "other", "over", "under", "very",
        "will", "would", "could", "should", "shall", "might", "must", "does", "doing",
        "while", "your", "yours", "ours", "hers", "him", "his", "her", "its"
    ]
}
