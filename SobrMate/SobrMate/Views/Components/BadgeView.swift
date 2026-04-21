import SwiftUI

struct BadgeView: View {
    let achievement: Achievement
    let habit: Habit

    private var earned: Bool { achievement.isEarned(for: habit) }

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(earned ? habit.palette.solid.opacity(0.25) : AppColor.cardRaised)
                    .frame(width: 64, height: 64)
                Image(systemName: achievement.icon)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(earned ? habit.palette.solid : AppColor.mutedText)
                if earned {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 16, height: 16)
                        .overlay(Image(systemName: "checkmark").font(.system(size: 9, weight: .bold)).foregroundStyle(.white))
                        .offset(x: 24, y: -24)
                }
            }

            Text(achievement.title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text(achievement.subtitle)
                .font(.system(size: 10))
                .foregroundStyle(AppColor.mutedText)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Text(earned ? "Earned today" : "\(achievement.daysRequired) days")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(earned ? Color.green : AppColor.mutedText)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Capsule().fill(earned ? Color.green.opacity(0.15) : AppColor.cardRaised))
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(AppColor.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(earned ? habit.palette.solid.opacity(0.4) : Color.clear, lineWidth: 1)
        )
    }
}
