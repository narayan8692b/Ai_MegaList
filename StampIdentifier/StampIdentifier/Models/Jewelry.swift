import Foundation

enum JewelryType: String, Codable, CaseIterable, Identifiable, Hashable {
    case ring      = "Ring"
    case necklace  = "Necklace"
    case bracelet  = "Bracelet"
    case earrings  = "Earrings"
    case brooch    = "Brooch"
    case pendant   = "Pendant"
    case watch     = "Watch"
    case other     = "Other"

    var id: String { rawValue }
}

enum JewelryEra: String, Codable, CaseIterable, Identifiable, Hashable {
    case antique   = "Antique (pre-1920)"
    case vintage   = "Vintage (1920-1980)"
    case modern    = "Modern (c.1980+)"

    var id: String { rawValue }

    var shortLabel: String {
        switch self {
        case .antique: return "Antique"
        case .vintage: return "Vintage"
        case .modern:  return "Modern"
        }
    }
}

struct MetalComponent: Codable, Hashable {
    var material: String       // e.g. "Yellow Gold"
    var karat: String          // e.g. "18K (75%)"
    var estimatedWeightGrams: Double

    var displayLine: String {
        let w = String(format: "%.1f", estimatedWeightGrams)
        return "\(karat) · \(w)g estimated"
    }
}

struct GemstoneComponent: Codable, Hashable {
    var species: String        // e.g. "Diamond"
    var caratWeight: Double    // e.g. 0.50
    var color: String?         // e.g. "G"
    var clarity: String?       // e.g. "VS2"
    var cut: String?           // e.g. "Cushion"

    var displayLine: String {
        var parts: [String] = [String(format: "%.2fct", caratWeight)]
        if let clarity { parts.append(clarity) }
        if let color { parts.append(color) }
        return parts.joined(separator: " · ")
    }
}

struct Jewelry: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var shortTitle: String
    var type: JewelryType
    var era: JewelryEra
    var yearMade: Int?

    var metals: [MetalComponent]
    var gemstones: [GemstoneComponent]
    var hallmarks: [String]

    var estimatedValue: Double
    var valueLow: Double
    var valueHigh: Double

    var summary: String
    var valueJustification: String
    var marketNotes: String

    var imageData: Data?
    var dateAdded: Date = Date()

    var eraLabel: String {
        if let y = yearMade {
            return "\(era.shortLabel) (c.\(y)s)"
        }
        return era.rawValue
    }

    var estimatedValueDisplay: String {
        CurrencyFormatter.usd.string(from: NSNumber(value: estimatedValue))
            ?? "$\(Int(estimatedValue))"
    }

    var valueRangeDisplay: String {
        let lo = CurrencyFormatter.usd.string(from: NSNumber(value: valueLow)) ?? "$\(Int(valueLow))"
        let hi = CurrencyFormatter.usd.string(from: NSNumber(value: valueHigh)) ?? "$\(Int(valueHigh))"
        return "Typical range: \(lo) - \(hi)"
    }
}

extension Jewelry {
    static let sampleSolitaire = Jewelry(
        name: "IGI Certified 3ct G Color Cushion Cut Diamond Solitaire Ring",
        shortTitle: "Cushion Cut Halo",
        type: .ring,
        era: .modern,
        yearMade: 2020,
        metals: [
            MetalComponent(material: "Yellow Gold", karat: "14K (58.5%)", estimatedWeightGrams: 4.0)
        ],
        gemstones: [
            GemstoneComponent(species: "Diamond", caratWeight: 3.00, color: "G",
                              clarity: "VS2", cut: "Cushion")
        ],
        hallmarks: ["585", "IGI"],
        estimatedValue: 1650,
        valueLow: 1500,
        valueHigh: 1900,
        summary: "A modern 14K yellow gold ring featuring a prominent 3-carat cushion-cut diamond, graded G color and IGI certified. The diamond is set in a secure bezel setting, showcasing its brilliance. The piece is in new condition and aligns with current market trends for lab-grown solitaire designs.",
        valueJustification: "Metal: 4.0g 14K gold (spot $75.6/g * 0.585 * 4.0g) = ~$177. Diamond: 3.00ct G/VS2 lab-grown wholesale = ~$1,200. Base material value = ~$1,377. Craftsmanship multiplier (cast, simple bezel) 1.2x = ~$1,652. Condition adjustment (New) 1.0x = ~$1,652. Market demand factor (solitaire rings steady) 1.0x. Calculated value ~$1,652. Rounded estimate: $1,650.",
        marketNotes: "Comparable lab-grown solitaires with 14K gold settings sell for $1,400-$1,900 on secondary markets."
    )

    static let sampleBaroquePearl = Jewelry(
        name: "Modern Yellow Gold Baroque Pearl Signet Ring",
        shortTitle: "Modern Yellow Gold Baroque",
        type: .ring,
        era: .modern,
        yearMade: 2023,
        metals: [
            MetalComponent(material: "Yellow Gold", karat: "14K (58.5%)", estimatedWeightGrams: 7.5)
        ],
        gemstones: [
            GemstoneComponent(species: "Baroque Pearl", caratWeight: 18.0, color: "White",
                              clarity: nil, cut: "Baroque")
        ],
        hallmarks: ["585"],
        estimatedValue: 3550,
        valueLow: 3000,
        valueHigh: 4000,
        summary: "This is a modern signet ring, likely from the 2020s, crafted in 14K yellow gold. It features a substantial 7.5-gram gold weight and is set with a striking baroque pearl, estimated to be between 15-20 carats, displaying white with silver overtones. The ring has a smooth, polished finish and a secure bezel setting for the pearl, indicative of good quality modern casting. It is in excellent condition.",
        valueJustification: "Metal: 7.5g 14K gold (spot $75.6/g * 0.585 * 7.5g) = ~$332. Pearl: natural baroque 18ct white, G/A grade = ~$1,800. Base material value = ~$2,132. Craftsmanship multiplier (cast, signet form) 1.6x = ~$3,411. Condition adjustment (Excellent) 1.05x = ~$3,582. Market demand factor (baroque pearl signet rings trending) 1.0x. Calculated value ~$3,582. Rounded estimate: $3,550.",
        marketNotes: "Comparable modern signet rings with baroque pearls sell in the $3,000-$4,000 range on eBay and Etsy."
    )

    static let seedCollection: [Jewelry] = [
        Jewelry(
            name: "Abstract Bypass Ring",
            shortTitle: "Abstract Bypass Ring",
            type: .ring,
            era: .modern,
            yearMade: 2022,
            metals: [MetalComponent(material: "Yellow Gold", karat: "18K (75%)", estimatedWeightGrams: 5.2)],
            gemstones: [],
            hallmarks: ["750"],
            estimatedValue: 1800,
            valueLow: 1500,
            valueHigh: 2200,
            summary: "A modern sculptural bypass ring in 18K yellow gold. Clean, contemporary design with a satin finish.",
            valueJustification: "Metal: 5.2g 18K gold (spot $75.6/g * 0.75 * 5.2g) = ~$295. Base material value = ~$295. Craftsmanship multiplier (cast, sculptural design) 5.5x = ~$1,625. Condition adjustment (Excellent) 1.1x = ~$1,788. Rounded estimate: $1,800.",
            marketNotes: "Contemporary designer bypass rings retail $1,500-$2,200."
        ),
        Jewelry(
            name: "Multi-Band Interlock Ring",
            shortTitle: "Multi-Band Interlock",
            type: .ring,
            era: .modern,
            yearMade: 2021,
            metals: [MetalComponent(material: "Yellow Gold Plated", karat: "Gold Plated", estimatedWeightGrams: 3.0)],
            gemstones: [],
            hallmarks: [],
            estimatedValue: 325,
            valueLow: 250,
            valueHigh: 450,
            summary: "Layered multi-band ring in gold-plated alloy. Fashion-grade piece popular in ready-to-wear collections.",
            valueJustification: "Materials (gold plate over base metal) ~$45. Craftsmanship (stamped, multi-band) 4.0x = ~$180. Brand multiplier 1.8x = ~$324. Rounded estimate: $325.",
            marketNotes: "Fashion multi-band rings retail $250-$450 at ready-to-wear designers."
        ),
        Jewelry.sampleBaroquePearl,
        Jewelry(
            name: "Cushion Cut Halo Ring",
            shortTitle: "Cushion Cut Halo",
            type: .ring,
            era: .modern,
            yearMade: 2019,
            metals: [MetalComponent(material: "Sterling Silver", karat: "925", estimatedWeightGrams: 3.4)],
            gemstones: [
                GemstoneComponent(species: "Cubic Zirconia", caratWeight: 2.5, color: "White",
                                  clarity: nil, cut: "Cushion")
            ],
            hallmarks: ["925"],
            estimatedValue: 45,
            valueLow: 25,
            valueHigh: 85,
            summary: "Sterling silver halo ring with a cushion-cut CZ center stone. Fashion-grade piece.",
            valueJustification: "Silver 3.4g = ~$3. Craftsmanship (cast, halo design) 8x = ~$24. Brand multiplier 1.9x = ~$45. Rounded estimate: $45.",
            marketNotes: "CZ halo rings in sterling retail $25-$85 at chain jewelers."
        )
    ]
}

// MARK: eBay checker support

struct EBayListingCheck: Hashable {
    var listingTitle: String
    var listingPrice: Double
    var fairPrice: Double
    var confidence: Double

    var percentDifference: Double {
        guard fairPrice > 0 else { return 0 }
        return (listingPrice - fairPrice) / fairPrice
    }

    var verdict: String {
        let pct = percentDifference
        if pct <= -0.05 { return "Fair Price" }
        if pct <= 0.05  { return "Market Price" }
        return "Overpriced"
    }

    var verdictDetail: String {
        let pct = Int(abs(percentDifference * 100).rounded())
        if percentDifference <= -0.05 { return "-\(pct)% below market" }
        if percentDifference >=  0.05 { return "+\(pct)% above market" }
        return "within market range"
    }
}

// MARK: Ask AI chat support

struct ChatMessage: Identifiable, Hashable {
    enum Role: String, Hashable { case user, assistant }
    let id: UUID = UUID()
    let role: Role
    let text: String
}
