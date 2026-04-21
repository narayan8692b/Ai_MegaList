import Foundation

struct Quote: Hashable {
    let text: String
    let author: String

    static let library: [Quote] = [
        Quote(text: "Your life does not get better by chance, it gets better by change.", author: "Jim Rohn"),
        Quote(text: "Fall seven times, stand up eight.", author: "Japanese Proverb"),
        Quote(text: "The secret of change is to focus all of your energy not on fighting the old, but on building the new.", author: "Socrates"),
        Quote(text: "You do not rise to the level of your goals. You fall to the level of your systems.", author: "James Clear"),
        Quote(text: "Rock bottom became the solid foundation on which I rebuilt my life.", author: "J.K. Rowling"),
        Quote(text: "What you get by achieving your goals is not as important as what you become by achieving your goals.", author: "Zig Ziglar"),
        Quote(text: "Every day is another chance to get stronger, to eat better, to live healthier, and to be the best version of you.", author: "Unknown")
    ]

    static func daily(seed: Date = Date()) -> Quote {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: seed) ?? 0
        return library[day % library.count]
    }
}
