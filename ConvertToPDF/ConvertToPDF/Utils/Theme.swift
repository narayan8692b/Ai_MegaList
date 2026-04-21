import SwiftUI

enum Theme {
    static let accent = Color(red: 0.86, green: 0.20, blue: 0.24)
    static let accentSoft = Color(red: 0.86, green: 0.20, blue: 0.24).opacity(0.12)
    static let background = Color(.systemBackground)
    static let surface = Color(.secondarySystemBackground)
    static let cardBorder = Color(.separator).opacity(0.4)
    static let primaryText = Color(.label)
    static let secondaryText = Color(.secondaryLabel)
}

extension View {
    func cardStyle() -> some View {
        self
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Theme.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Theme.cardBorder, lineWidth: 1)
                    )
            )
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Theme.accent)
            )
            .opacity(configuration.isPressed ? 0.85 : 1.0)
    }
}
