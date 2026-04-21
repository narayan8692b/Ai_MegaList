import Foundation

struct Habit: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var emoji: String
    var palette: HabitPalette
    var startDate: Date
    var motivation: String
    var relapses: [Date] = []

    var effectiveStart: Date {
        relapses.max() ?? startDate
    }

    var currentStreakDays: Int {
        Calendar.current.dateComponents([.day], from: startOfDay(effectiveStart), to: startOfDay(Date())).day ?? 0
    }

    var longestStreakDays: Int {
        var previous = startDate
        var longest = 0
        for relapse in relapses.sorted() {
            let days = Calendar.current.dateComponents([.day], from: startOfDay(previous), to: startOfDay(relapse)).day ?? 0
            longest = max(longest, days)
            previous = relapse
        }
        let ongoing = Calendar.current.dateComponents([.day], from: startOfDay(previous), to: startOfDay(Date())).day ?? 0
        return max(longest, ongoing)
    }

    func elapsed(from reference: Date = Date()) -> (days: Int, hours: Int, minutes: Int, seconds: Int) {
        let comps = Calendar.current.dateComponents(
            [.day, .hour, .minute, .second],
            from: effectiveStart,
            to: reference
        )
        return (
            max(0, comps.day ?? 0),
            max(0, comps.hour ?? 0),
            max(0, comps.minute ?? 0),
            max(0, comps.second ?? 0)
        )
    }

    private func startOfDay(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }
}

extension Habit {
    static let samples: [Habit] = [
        Habit(
            name: "Alcohol",
            emoji: "🍺",
            palette: .blue,
            startDate: Calendar.current.date(byAdding: .day, value: -9, to: Date()) ?? Date(),
            motivation: "Because I deserve a clearer mind and a better life."
        ),
        Habit(
            name: "Social Media",
            emoji: "📱",
            palette: .orange,
            startDate: Calendar.current.date(byAdding: .day, value: -4, to: Date()) ?? Date(),
            motivation: "Reclaim attention. Reclaim time."
        )
    ]
}
