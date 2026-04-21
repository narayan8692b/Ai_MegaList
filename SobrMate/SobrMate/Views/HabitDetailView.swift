import SwiftUI

struct HabitDetailView: View {
    @EnvironmentObject private var store: HabitStore
    @Environment(\.dismiss) private var dismiss

    let habitID: UUID
    @State private var showingAchievements = false
    @State private var showingEdit = false

    private var habit: Habit? {
        store.habits.first(where: { $0.id == habitID })
    }

    var body: some View {
        ScrollView {
            if let habit {
                VStack(spacing: 20) {
                    ringCard(for: habit)
                    statsCard(for: habit)
                    CalendarGridView(habit: habit)
                    achievementsLink(for: habit)
                    motivationCard(for: habit)
                    dangerZone(for: habit)
                }
                .padding(16)
            } else {
                ContentUnavailableView("Habit not found", systemImage: "questionmark.folder")
            }
        }
        .background(AppColor.background.ignoresSafeArea())
        .navigationTitle(habit?.name ?? "Habit")
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingEdit = true } label: {
                    Image(systemName: "pencil").foregroundStyle(.white)
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            if let habit { EditHabitView(habit: habit) }
        }
        .sheet(isPresented: $showingAchievements) {
            if let habit { AchievementsView(habit: habit) }
        }
    }

    @ViewBuilder
    private func ringCard(for habit: Habit) -> some View {
        VStack(spacing: 18) {
            StreakRingView(days: habit.currentStreakDays, palette: habit.palette)
                .padding(.top, 8)

            HStack(spacing: 28) {
                metric("\(habit.currentStreakDays)", "days")
                metric(hoursThisWeek(from: habit.effectiveStart), "weekly")
                metric(monthsLabel(from: habit.effectiveStart), "months")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(AppColor.card)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func statsCard(for habit: Habit) -> some View {
        SectionCard("Statistics") {
            StatRow(icon: "flame.fill", label: "Current Streak",
                    value: "\(habit.currentStreakDays) \(habit.currentStreakDays == 1 ? "day" : "days")",
                    tint: habit.palette.solid)
            Divider().background(AppColor.divider)
            StatRow(icon: "trophy.fill", label: "Longest Streak",
                    value: "\(habit.longestStreakDays) \(habit.longestStreakDays == 1 ? "day" : "days")",
                    tint: habit.palette.solid)
            Divider().background(AppColor.divider)
            StatRow(icon: "calendar", label: "Started", value: formatted(habit.startDate), tint: habit.palette.solid)
        }
    }

    private func achievementsLink(for habit: Habit) -> some View {
        Button { showingAchievements = true } label: {
            HStack {
                Image(systemName: "rosette")
                    .foregroundStyle(habit.palette.solid)
                Text("Achievements")
                    .foregroundStyle(.white)
                Spacer()
                Text("\(earnedCount(for: habit)) / \(Achievement.catalogue.count)")
                    .foregroundStyle(AppColor.mutedText)
                Image(systemName: "chevron.right")
                    .foregroundStyle(AppColor.mutedText)
            }
            .font(.system(size: 14, weight: .semibold))
            .padding(16)
            .background(AppColor.card)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private func motivationCard(for habit: Habit) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Why I'm Doing This", systemImage: "heart.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(habit.palette.solid)
            Text(habit.motivation.isEmpty ? "Tap edit to add your reason." : habit.motivation)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func dangerZone(for habit: Habit) -> some View {
        VStack(spacing: 12) {
            Button(role: .destructive) {
                store.resetStreak(for: habit)
            } label: {
                Label("Reset Streak", systemImage: "arrow.counterclockwise")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.red.opacity(0.85))

            Button(role: .destructive) {
                store.delete(habit)
                dismiss()
            } label: {
                Label("Delete Habit", systemImage: "trash")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
            .tint(.red)
        }
    }

    private func metric(_ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.system(size: 20, weight: .bold, design: .rounded)).foregroundStyle(.white)
            Text(label).font(.system(size: 11, weight: .medium)).foregroundStyle(AppColor.mutedText)
        }
    }

    private func hoursThisWeek(from start: Date) -> String {
        let weeks = Calendar.current.dateComponents([.weekOfYear], from: start, to: Date()).weekOfYear ?? 0
        return "\(weeks)"
    }

    private func monthsLabel(from start: Date) -> String {
        let months = Calendar.current.dateComponents([.month], from: start, to: Date()).month ?? 0
        return "\(months)"
    }

    private func earnedCount(for habit: Habit) -> Int {
        Achievement.catalogue.filter { $0.isEarned(for: habit) }.count
    }

    private func formatted(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }
}
