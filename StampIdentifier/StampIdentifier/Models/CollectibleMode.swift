import SwiftUI

enum CollectibleMode: String, CaseIterable, Identifiable, Hashable {
    case stamp   = "Stamps"
    case antique = "Antiques"

    var id: String { rawValue }

    var singular: String {
        switch self {
        case .stamp:   return "Stamp"
        case .antique: return "Antique"
        }
    }

    var systemImage: String {
        switch self {
        case .stamp:   return "envelope.badge"
        case .antique: return "crown"
        }
    }

    var accentColor: Color {
        switch self {
        case .stamp:   return .brandOrange
        case .antique: return .antiqueGold
        }
    }
}
