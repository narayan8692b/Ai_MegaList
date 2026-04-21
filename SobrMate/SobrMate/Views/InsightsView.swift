import SwiftUI

struct InsightsView: View {
    @EnvironmentObject private var store: HabitStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    overview
                    habitProgress
                }
                .padding(16)
            }
            .background(AppColor.background.ignoresSafeArea())
            .navigationTitle("Insights")
        }
    }

    private var overview: some View {
        SectionCard("Statistics") {
            StatRow(icon: "square.grid.2x2.fill", label: "Total Habits",
                    value: "\(store.totalHabits)")
            Divider().background(AppColor.divider)
            StatRow(icon: "chart.line.uptrend.xyaxis", label: "Average Streak",
                    value: String(format: "%.1f days", store.averageStreak))
            Divider().background(AppColor.divider)
            StatRow(icon: "flame.fill", label: "Best Current Streak",
                    value: "\(store.bestCurrentStreak) days")
        }
    }

    private var habitProgress: some View {
        SectionCard("Habit Progress") {
            if store.habits.isEmpty {
                Text("Add your first tracker to see progress.")
                    .foregroundStyle(AppColor.mutedText)
                    .padding(.vertical, 16)
            } else {
                ForEach(Array(store.habits.enumerated()), id: \.element.id) { index, habit in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("\(habit.emoji) \(habit.name)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                            Spacer()
                            Text("\(habit.currentStreakDays) days")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(habit.palette.solid)
                        }
                        progressBar(for: habit)
                        Text("Started \(shortDate(habit.startDate))")
                            .font(.system(size: 11))
                            .foregroundStyle(AppColor.mutedText)
                    }
                    .padding(.vertical, 10)

                    if index < store.habits.count - 1 {
                        Divider().background(AppColor.divider)
                    }
                }
            }
        }
    }

    private func progressBar(for habit: Habit) -> some View {
        let milestones = [7, 30, 90, 180, 365]
        let target = Double(milestones.first(where: { $0 > habit.currentStreakDays }) ?? max(habit.currentStreakDays, 1))
        let value = min(1.0, Double(habit.currentStreakDays) / target)
        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6).fill(AppColor.cardRaised)
                RoundedRectangle(cornerRadius: 6)
                    .fill(LinearGradient(colors: habit.palette.gradient, startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(6, geo.size.width * value))
            }
        }
        .frame(height: 8)
    }

    private func shortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f.string(from: date)
    }
}
