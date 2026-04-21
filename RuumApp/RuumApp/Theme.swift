import SwiftUI

extension Color {
    static let ruumTeal = Color(red: 0.16, green: 0.54, blue: 0.54)
    static let ruumTealDark = Color(red: 0.10, green: 0.42, blue: 0.42)
    static let ruumBackground = Color(.systemGroupedBackground)
    static let ruumCard = Color(.secondarySystemGroupedBackground)
    static let ruumMuted = Color.secondary.opacity(0.6)
}

enum Layout {
    static let cardRadius: CGFloat = 20
    static let tileRadius: CGFloat = 16
    static let padding: CGFloat = 16
}

struct PrimaryButtonStyle: ButtonStyle {
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isEnabled ? Color.ruumTeal : Color.ruumTeal.opacity(0.4))
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
    }
}
