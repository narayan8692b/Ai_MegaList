import SwiftUI

struct StreakRingView: View {
    let days: Int
    let palette: HabitPalette
    var size: CGFloat = 200
    var lineWidth: CGFloat = 14

    private var target: Int {
        let milestones = [7, 30, 90, 180, 365, 730]
        return milestones.first(where: { $0 > days }) ?? max(days, 1)
    }

    private var progress: Double {
        min(1.0, Double(days) / Double(target))
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppColor.cardRaised, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(colors: palette.gradient, startPoint: .topLeading, endPoint: .bottomTrailing),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: progress)

            VStack(spacing: 2) {
                Text("\(days)")
                    .font(.system(size: size * 0.26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(days == 1 ? "day" : "days")
                    .font(.system(size: size * 0.08, weight: .medium))
                    .foregroundStyle(AppColor.mutedText)
            }
        }
        .frame(width: size, height: size)
    }
}
