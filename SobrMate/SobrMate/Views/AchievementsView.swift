import SwiftUI

struct AchievementsView: View {
    @Environment(\.dismiss) private var dismiss
    let habit: Habit

    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(Achievement.catalogue) { achievement in
                        BadgeView(achievement: achievement, habit: habit)
                    }
                }
                .padding(16)
            }
            .background(AppColor.background.ignoresSafeArea())
            .navigationTitle("\(habit.name) Achievements")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
