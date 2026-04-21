import SwiftUI

enum DesignMode: String, CaseIterable, Identifiable, Codable {
    case interior
    case emptyRoom
    case exterior
    case removeObjects

    var id: String { rawValue }

    var title: String {
        switch self {
        case .interior:      return "Interior"
        case .emptyRoom:     return "Empty Room"
        case .exterior:      return "Exterior"
        case .removeObjects: return "Remove Objects"
        }
    }

    var subtitle: String {
        switch self {
        case .interior:      return "Restyle any room"
        case .emptyRoom:     return "Fill a blank space"
        case .exterior:      return "Refresh the outside"
        case .removeObjects: return "Clear clutter instantly"
        }
    }

    var sfSymbol: String {
        switch self {
        case .interior:      return "house.fill"
        case .emptyRoom:     return "square.dashed"
        case .exterior:      return "building.2.fill"
        case .removeObjects: return "wand.and.stars"
        }
    }

    var gradient: [Color] {
        switch self {
        case .interior:      return [Color(hex: "#7C6CE0"), Color(hex: "#4A3FBE")]
        case .emptyRoom:     return [Color(hex: "#F28B82"), Color(hex: "#C25A52")]
        case .exterior:      return [Color(hex: "#6FD1A0"), Color(hex: "#2F8C66")]
        case .removeObjects: return [Color(hex: "#F6A15C"), Color(hex: "#D26A2A")]
        }
    }
}
