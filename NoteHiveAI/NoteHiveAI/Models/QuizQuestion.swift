import Foundation

struct QuizQuestion: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var question: String
    var options: [String]
    var correctIndex: Int
}
