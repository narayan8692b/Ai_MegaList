import Foundation

struct FlashCard: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var question: String
    var answer: String
}
