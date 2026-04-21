import SwiftUI

struct TimeCounterView: View {
    let days: Int
    let hours: Int
    let minutes: Int
    let seconds: Int
    var tint: Color = .white

    var body: some View {
        HStack(spacing: 18) {
            unit(value: days,    label: "DAYS")
            unit(value: hours,   label: "HOURS")
            unit(value: minutes, label: "MINS")
            unit(value: seconds, label: "SECS")
        }
    }

    @ViewBuilder
    private func unit(value: Int, label: String) -> some View {
        VStack(spacing: 4) {
            Text(String(format: "%02d", value))
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(tint)
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(tint.opacity(0.75))
        }
        .frame(minWidth: 52)
    }
}
