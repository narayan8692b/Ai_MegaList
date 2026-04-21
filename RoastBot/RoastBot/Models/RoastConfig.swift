import Foundation

enum RoastStyle: String, CaseIterable, Identifiable, Codable {
    case friendly   = "Friendly"
    case savage     = "Savage"
    case playful    = "Playful"
    case sarcastic  = "Sarcastic"
    case battle     = "Battle"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .friendly:  return "😊"
        case .savage:    return "🔥"
        case .playful:   return "😜"
        case .sarcastic: return "😏"
        case .battle:    return "⚔️"
        }
    }

    var prompt: String {
        switch self {
        case .friendly:
            return "Keep it light and good-natured. Playful teasing a friend would laugh at."
        case .savage:
            return "Go hard. Brutal, scathing roasts with no mercy. Maximum fire."
        case .playful:
            return "Fun and silly, like a comedy roast between best friends."
        case .sarcastic:
            return "Dripping with sarcasm and dry wit. Deadpan delivery."
        case .battle:
            return "Rap-battle style — rhythmic, punchy, quotable bars meant to destroy in a battle."
        }
    }
}

struct RoastConfig {
    var style: RoastStyle = .savage
    var intensity: Double = 0.8  // 0.0 – 1.0
    var count: Int = 3

    var intensityPercent: Int { Int(intensity * 100) }

    var intensityLabel: String {
        switch intensity {
        case ..<0.34: return "Mild"
        case ..<0.67: return "Medium"
        default:      return "Nuclear"
        }
    }
}
