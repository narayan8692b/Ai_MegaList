import SwiftUI

struct HabitCardView: View {
    let habit: Habit
    let now: Date

    var body: some View {
        let elapsed = habit.elapsed(from: now)

        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Text(habit.emoji)
                    .font(.system(size: 20))
                Text("I've been \(habit.name) free for")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
                Spacer()
            }

            TimeCounterView(
                days: elapsed.days,
                hours: elapsed.hours,
                minutes: elapsed.minutes,
                seconds: elapsed.seconds
            )
            .frame(maxWidth: .infinity)

            HStack {
                Spacer()
                Text("Current streak: \(habit.currentStreakDays) \(habit.currentStreakDays == 1 ? "day" : "days")")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
                Spacer()
            }
        }
        .padding(20)
        .background(
            LinearGradient(colors: habit.palette.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: habit.palette.solid.opacity(0.35), radius: 16, x: 0, y: 8)
    }
}
