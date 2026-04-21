import SwiftUI

enum AppColor {
    static let background = Color(red: 0.05, green: 0.06, blue: 0.09)
    static let card = Color(red: 0.10, green: 0.11, blue: 0.14)
    static let cardRaised = Color(red: 0.13, green: 0.14, blue: 0.18)
    static let accent = Color(red: 0.45, green: 0.48, blue: 0.98)
    static let mutedText = Color.white.opacity(0.55)
    static let divider = Color.white.opacity(0.08)
}

enum HabitPalette: String, CaseIterable, Codable, Identifiable {
    case blue, red, orange, green, purple, pink, teal, yellow

    var id: String { rawValue }

    var gradient: [Color] {
        switch self {
        case .blue:   return [Color(red: 0.30, green: 0.62, blue: 0.98), Color(red: 0.20, green: 0.45, blue: 0.90)]
        case .red:    return [Color(red: 0.95, green: 0.35, blue: 0.35), Color(red: 0.80, green: 0.20, blue: 0.25)]
        case .orange: return [Color(red: 0.98, green: 0.62, blue: 0.20), Color(red: 0.92, green: 0.45, blue: 0.10)]
        case .green:  return [Color(red: 0.30, green: 0.82, blue: 0.55), Color(red: 0.15, green: 0.65, blue: 0.42)]
        case .purple: return [Color(red: 0.62, green: 0.45, blue: 0.98), Color(red: 0.45, green: 0.28, blue: 0.85)]
        case .pink:   return [Color(red: 0.98, green: 0.45, blue: 0.72), Color(red: 0.85, green: 0.28, blue: 0.58)]
        case .teal:   return [Color(red: 0.28, green: 0.80, blue: 0.80), Color(red: 0.15, green: 0.60, blue: 0.65)]
        case .yellow: return [Color(red: 0.98, green: 0.82, blue: 0.30), Color(red: 0.90, green: 0.68, blue: 0.15)]
        }
    }

    var solid: Color { gradient[0] }
}
