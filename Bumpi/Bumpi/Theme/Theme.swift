import SwiftUI

enum BumpiTheme {
    static let primary = Color(red: 0.86, green: 0.32, blue: 0.47)
    static let primaryDark = Color(red: 0.62, green: 0.19, blue: 0.31)
    static let accent = Color(red: 0.96, green: 0.62, blue: 0.70)
    static let softPink = Color(red: 1.00, green: 0.92, blue: 0.94)
    static let cardBackground = Color.white
    static let background = LinearGradient(
        colors: [
            Color(red: 1.00, green: 0.94, blue: 0.95),
            Color(red: 0.99, green: 0.89, blue: 0.93),
            Color(red: 0.96, green: 0.88, blue: 0.94)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    static let textPrimary = Color(red: 0.16, green: 0.10, blue: 0.14)
    static let textSecondary = Color(red: 0.45, green: 0.35, blue: 0.40)
}

struct BumpiPrimaryButtonStyle: ButtonStyle {
    var enabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [BumpiTheme.primary, BumpiTheme.primaryDark],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: BumpiTheme.primary.opacity(0.35), radius: 14, x: 0, y: 8)
            .opacity(enabled ? 1 : 0.5)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct BumpiSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(BumpiTheme.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(BumpiTheme.softPink)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension View {
    func bumpiCard() -> some View {
        self
            .background(BumpiTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
    }
}
