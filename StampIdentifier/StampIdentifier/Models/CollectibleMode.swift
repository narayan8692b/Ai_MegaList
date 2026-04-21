import SwiftUI

enum CollectibleMode: String, CaseIterable, Identifiable, Hashable {
    case stamp   = "Stamps"
    case antique = "Antiques"
    case jewelry = "Jewelry"
    case coin    = "Coins"

    var id: String { rawValue }

    var singular: String {
        switch self {
        case .stamp:   return "Stamp"
        case .antique: return "Antique"
        case .jewelry: return "Jewelry"
        case .coin:    return "Coin"
        }
    }

    var systemImage: String {
        switch self {
        case .stamp:   return "envelope.badge"
        case .antique: return "crown"
        case .jewelry: return "sparkles"
        case .coin:    return "dollarsign.circle"
        }
    }

    var accentColor: Color {
        switch self {
        case .stamp:   return .brandOrange
        case .antique: return .antiqueGold
        case .jewelry: return .jewelryGold
        case .coin:    return .coinGold
        }
    }

    var backgroundColor: Color {
        switch self {
        case .stamp:   return .brandCream
        case .antique: return .antiqueCream
        case .jewelry: return .jewelryCream
        case .coin:    return .coinCream
        }
    }
}
