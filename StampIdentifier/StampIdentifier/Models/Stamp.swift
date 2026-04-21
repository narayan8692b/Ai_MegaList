import Foundation
import SwiftUI

enum Rarity: String, Codable, CaseIterable, Identifiable {
    case common = "Common"
    case uncommon = "Uncommon"
    case rare = "Rare"
    case legendary = "Legendary"

    var id: String { rawValue }

    var tintColor: Color {
        switch self {
        case .common:    return Color(red: 0.45, green: 0.55, blue: 0.45)
        case .uncommon:  return Color(red: 0.25, green: 0.50, blue: 0.75)
        case .rare:      return Color(red: 0.65, green: 0.30, blue: 0.65)
        case .legendary: return Color(red: 0.85, green: 0.45, blue: 0.10)
        }
    }

    var symbol: String {
        switch self {
        case .common:    return "circle.fill"
        case .uncommon:  return "star.fill"
        case .rare:      return "sparkles"
        case .legendary: return "crown.fill"
        }
    }
}

struct StampValueRange: Codable, Hashable {
    var low: Double
    var high: Double
    var currency: String = "USD"

    var displayRange: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        let lowStr = formatter.string(from: NSNumber(value: low)) ?? "\(Int(low))"
        let highStr = formatter.string(from: NSNumber(value: high)) ?? "\(Int(high))"
        return "\(lowStr)-\(highStr) \(currency)"
    }

    var midpoint: Double { (low + high) / 2 }
}

struct Stamp: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var country: String
    var yearIssued: Int?
    var denomination: String
    var catalogNumbers: [String]
    var rarity: Rarity
    var valueRange: StampValueRange
    var estimatedValue: Double
    var aiConfidence: Double
    var description: String
    var physicalAnalysis: String
    var historicalContext: String
    var valueAnalysis: String
    var collectorInfo: String
    var additionalNotes: String
    var imageData: Data?
    var dateAdded: Date = Date()

    var catalogNumbersDisplay: String {
        catalogNumbers.joined(separator: ", ")
    }

    var yearDisplay: String {
        yearIssued.map(String.init) ?? "Unknown"
    }
}

extension Stamp {
    static let samplePennyBlack = Stamp(
        name: "Penny Black",
        country: "Great Britain",
        yearIssued: 1840,
        denomination: "1d",
        catalogNumbers: ["Stanley Gibbons 1", "Scott 1"],
        rarity: .legendary,
        valueRange: StampValueRange(low: 150_000, high: 300_000),
        estimatedValue: 250_000,
        aiConfidence: 0.95,
        description: "This is a Great Britain 1d Black stamp, issued in 1840. It is the world's first adhesive postage stamp. The specific stamp in the image appears to be from plate 77, which is one of the rarer plates. The condition is fair to good, with some signs of wear and possible minor imperfections. The cancellation is not clearly visible to determine its impact on value.",
        physicalAnalysis: "Imperforate, black ink on white paper. Check-letters visible in lower corners (A-K). Watermark: Small Crown. Signs of light age-toning along margins; no tears.",
        historicalContext: "Issued 1 May 1840 as part of Rowland Hill's postal reforms, the Penny Black was the world's first adhesive postage stamp. Plate 77 was removed after a short printing run due to cracks, making surviving examples exceptionally scarce.",
        valueAnalysis: "Unused Plate 77 examples have realized six-figure sums at auction. Used examples command a significant premium over standard plates. Value is highly sensitive to margins, plate, and cancellation clarity.",
        collectorInfo: "Highly sought by classic British philately collectors. Certification from the Royal Philatelic Society London is recommended for any plate-77 example.",
        additionalNotes: "Image suggests plate characteristics consistent with a scarcer printing. Professional expertisation strongly recommended before valuation is finalized."
    )

    static let seedCollection: [Stamp] = [
        Stamp(
            name: "Silver Jubilee of King George V",
            country: "Great Britain",
            yearIssued: 1935,
            denomination: "½d",
            catalogNumbers: ["Stanley Gibbons 453", "Scott 226"],
            rarity: .uncommon,
            valueRange: StampValueRange(low: 2, high: 15),
            estimatedValue: 8,
            aiConfidence: 0.91,
            description: "Part of the 1935 Silver Jubilee set marking 25 years of King George V's reign.",
            physicalAnalysis: "Photogravure printing, perforation 15 x 14, watermark Multiple Block Cypher.",
            historicalContext: "Issued 7 May 1935 to celebrate the Silver Jubilee of King George V. Designed by Barnett Freedman.",
            valueAnalysis: "Common in used condition; unmounted mint examples with strong color command a premium.",
            collectorInfo: "Popular entry-point issue for British commemorative collectors.",
            additionalNotes: "This stamp is part of a set issued to celebrate the 25th anniversary of the accession of King George V. While the design is common for this issue, variations in shade and condition can affect value."
        ),
        Stamp(
            name: "King George V 2d Purple",
            country: "Great Britain",
            yearIssued: 1912,
            denomination: "2d",
            catalogNumbers: ["Stanley Gibbons 368", "Scott 162"],
            rarity: .uncommon,
            valueRange: StampValueRange(low: 1, high: 10),
            estimatedValue: 5,
            aiConfidence: 0.88,
            description: "King George V definitive, 2d purple, part of the Downey Head / Profile Head series.",
            physicalAnalysis: "Typographed issue, watermark Royal Cypher.",
            historicalContext: "Early definitive of the reign of King George V, in circulation for everyday correspondence.",
            valueAnalysis: "Values depend heavily on shade and plate variety.",
            collectorInfo: "Shade studies are a popular specialism within this issue.",
            additionalNotes: ""
        ),
        Stamp(
            name: "King Charles III Profile 1st",
            country: "Great Britain",
            yearIssued: 2023,
            denomination: "1st",
            catalogNumbers: ["Stanley Gibbons 5052"],
            rarity: .common,
            valueRange: StampValueRange(low: 0, high: 1),
            estimatedValue: 1,
            aiConfidence: 0.97,
            description: "First definitive of King Charles III, based on a profile by Martin Jennings.",
            physicalAnalysis: "Self-adhesive, gravure print, barcode tab at right.",
            historicalContext: "Issued in 2023 following the accession of King Charles III.",
            valueAnalysis: "Face value; no premium in current market.",
            collectorInfo: "Of interest to modern GB specialists; watch for printing varieties.",
            additionalNotes: ""
        ),
        Stamp(
            name: "King Charles III Definitive £3.40",
            country: "Great Britain",
            yearIssued: 2023,
            denomination: "£3.40",
            catalogNumbers: ["Stanley Gibbons 5054"],
            rarity: .common,
            valueRange: StampValueRange(low: 1, high: 5),
            estimatedValue: 4,
            aiConfidence: 0.96,
            description: "High-value definitive of the King Charles III series.",
            physicalAnalysis: "Gravure print, green hue, self-adhesive.",
            historicalContext: "Issued as part of the 2023 Charles III definitive series for higher-value postage.",
            valueAnalysis: "Near face value; price tracks postal tariff changes.",
            collectorInfo: "Complete sets are popular with modern GB collectors.",
            additionalNotes: ""
        ),
        Stamp(
            name: "Postage Revenue",
            country: "Great Britain",
            yearIssued: 1953,
            denomination: "1d",
            catalogNumbers: ["Stanley Gibbons 540"],
            rarity: .common,
            valueRange: StampValueRange(low: 0, high: 2),
            estimatedValue: 1,
            aiConfidence: 0.92,
            description: "Low-value definitive from the Queen Elizabeth II Wilding series.",
            physicalAnalysis: "Watermark Tudor Crown, photogravure.",
            historicalContext: "Issued shortly after the 1953 coronation as part of the first definitive series of Elizabeth II.",
            valueAnalysis: "Used examples are very common; unmounted mint with sound margins is collectible.",
            collectorInfo: "Wilding issues are a rich field for watermark and perforation studies.",
            additionalNotes: ""
        )
    ]
}
