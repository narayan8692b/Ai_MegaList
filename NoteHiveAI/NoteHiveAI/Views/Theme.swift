import SwiftUI

enum Theme {
    static let background = Color(red: 0.04, green: 0.04, blue: 0.07)
    static let card = Color(red: 0.11, green: 0.11, blue: 0.16)
    static let cardStroke = Color.white.opacity(0.06)
    static let accent = Color(red: 0.45, green: 0.45, blue: 0.95)
    static let accentSoft = Color(red: 0.45, green: 0.45, blue: 0.95).opacity(0.18)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.65)
    static let textTertiary = Color.white.opacity(0.4)
    static let pillInactive = Color.white.opacity(0.04)
    static let pillStroke = Color.white.opacity(0.12)
    static let durationBadge = Color(red: 0.98, green: 0.55, blue: 0.25)
}

struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Theme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Theme.cardStroke, lineWidth: 1)
            )
    }
}

extension View {
    func cardBackground() -> some View { modifier(CardBackground()) }
}
