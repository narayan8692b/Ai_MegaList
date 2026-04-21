import Foundation

struct Achievement: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let daysRequired: Int

    func isEarned(for habit: Habit) -> Bool {
        habit.currentStreakDays >= daysRequired
    }

    static let catalogue: [Achievement] = [
        Achievement(id: "first-step",     title: "First Step",         subtitle: "Started your journey to break a bad habit",   icon: "flag.fill",              daysRequired: 0),
        Achievement(id: "one-week",       title: "One Week Strong",    subtitle: "Stayed clean for 7 days",                     icon: "star.circle.fill",       daysRequired: 7),
        Achievement(id: "one-month",      title: "One Month Milestone",subtitle: "Stayed clean for 30 days",                    icon: "calendar.circle.fill",   daysRequired: 30),
        Achievement(id: "three-months",   title: "Three Months",       subtitle: "Stayed clean for 90 days",                    icon: "trophy.fill",            daysRequired: 90),
        Achievement(id: "six-months",     title: "Six Months",         subtitle: "Stayed clean for 180 days",                   icon: "crown.fill",             daysRequired: 180),
        Achievement(id: "one-year",       title: "One Year",           subtitle: "Stayed clean for 365 days",                   icon: "sparkles",               daysRequired: 365)
    ]
}
