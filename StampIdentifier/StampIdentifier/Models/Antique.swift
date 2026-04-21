import Foundation

enum AntiqueCategory: String, Codable, CaseIterable, Identifiable, Hashable {
    case metalware     = "Metalware"
    case ceramics      = "Ceramics"
    case furniture     = "Furniture"
    case glass         = "Glass"
    case jewelry       = "Jewelry"
    case clocks        = "Clocks & Watches"
    case textiles      = "Textiles"
    case toys          = "Toys & Games"
    case art           = "Fine Art"
    case other         = "Other"

    var id: String { rawValue }
}

struct AntiqueValueRange: Codable, Hashable {
    var low: Double
    var high: Double
    var currency: String = "USD"

    var displayRange: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 0
        let lowStr = formatter.string(from: NSNumber(value: low)) ?? "$\(Int(low))"
        let highStr = formatter.string(from: NSNumber(value: high)) ?? "$\(Int(high))"
        return "\(lowStr) - \(highStr)"
    }
}

struct Antique: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var shortTitle: String
    var yearMade: Int?
    var category: AntiqueCategory
    var subcategory: String
    var style: String
    var origin: String
    var maker: String

    var valueRange: AntiqueValueRange
    var estimatedValue: Double
    var aiConfidence: Double

    // Detail sections (mirror the App Store screenshot)
    var itemIdentification: String
    var datingAge: String
    var originProvenance: String
    var materialsConstruction: String
    var physicalCharacteristics: String
    var conditionAssessment: String
    var valuation: String
    var raritySignificance: String
    var authenticityAuthentication: String

    var imageData: Data?
    var dateAdded: Date = Date()

    var yearDisplay: String {
        yearMade.map(String.init) ?? "Unknown"
    }
}

extension Antique {
    static let sampleBronzeVase = Antique(
        name: "Antique Bronze Vase with Relief Decoration",
        shortTitle: "Bronze Vase",
        yearMade: 1880,
        category: .metalware,
        subcategory: "Vase",
        style: "Art Nouveau",
        origin: "France",
        maker: "Unattributed foundry",
        valueRange: AntiqueValueRange(low: 500, high: 2000),
        estimatedValue: 1200,
        aiConfidence: 0.75,
        itemIdentification: "Cast bronze vase with high-relief figural decoration depicting a mythological scene. Baluster form with flared rim, standing on a stepped circular foot.",
        datingAge: "Late 19th century, circa 1880. The casting technique and patina are consistent with European foundries of the period.",
        originProvenance: "Likely French or Belgian manufacture. No foundry mark is visible; provenance is undocumented but the iconography suggests a Paris-Salon influenced workshop.",
        materialsConstruction: "Solid bronze, sand-cast in multiple sections and hand-chased. Rich brown-to-green patina with highlights on raised surfaces.",
        physicalCharacteristics: "Height approximately 14 inches, rim diameter 5 inches. Weight substantial. Surface shows controlled oxidation with no major losses.",
        conditionAssessment: "Good overall. Minor surface scratches and a small dent near the base. Patina intact and unrestored. No cracks or repairs detected.",
        valuation: "Comparable mid-scale Art Nouveau figural bronzes have realized $500-$2,000 at regional auction. Stronger attribution or foundry marks would lift the high estimate.",
        raritySignificance: "Moderate rarity. Decorative Art Nouveau bronzes are collected but not scarce. Distinctive compositions and named artists command premiums.",
        authenticityAuthentication: "Period-consistent construction and patina support a late-19th-century attribution. Recommend specialist inspection for foundry marks or signature under the base before firm valuation."
    )

    static let seedCollection: [Antique] = [
        Antique(
            name: "Novelty Train-Shaped Table Clock",
            shortTitle: "Train Clock",
            yearMade: 1920,
            category: .clocks,
            subcategory: "Novelty Clock",
            style: "Art Deco",
            origin: "Germany",
            maker: "Unknown",
            valueRange: AntiqueValueRange(low: 150, high: 450),
            estimatedValue: 280,
            aiConfidence: 0.82,
            itemIdentification: "Figural mantel clock cast as a locomotive, with a round dial integrated into the boiler.",
            datingAge: "Circa 1920s, Art Deco period.",
            originProvenance: "German novelty-clock makers dominated this market; unmarked examples are common.",
            materialsConstruction: "Spelter body with patinated finish, glass dial cover, brass hands.",
            physicalCharacteristics: "Approximately 10 inches long. Movement runs when wound.",
            conditionAssessment: "Working movement, minor wear to patina on raised elements.",
            valuation: "Typical retail $150-$450 depending on running condition.",
            raritySignificance: "Common as a category; distinctive examples in working order trend higher.",
            authenticityAuthentication: "Consistent construction; no obvious repaints."
        ),
        Antique(
            name: "Reproduction Antique-Style Rotary Telephone",
            shortTitle: "Rotary Telephone",
            yearMade: 1980,
            category: .other,
            subcategory: "Telephone",
            style: "Reproduction Victorian",
            origin: "East Asia",
            maker: "Various",
            valueRange: AntiqueValueRange(low: 20, high: 75),
            estimatedValue: 45,
            aiConfidence: 0.88,
            itemIdentification: "Decorative telephone in Victorian style; modern reproduction.",
            datingAge: "Late 20th century reproduction, not a genuine antique.",
            originProvenance: "Mass-produced for the decorative market.",
            materialsConstruction: "Plastic housing with brass-finish trim.",
            physicalCharacteristics: "Tabletop scale; functional rotary dial.",
            conditionAssessment: "Typically good; value depends on working line compatibility.",
            valuation: "Decorative value only — $20-$75.",
            raritySignificance: "Not rare.",
            authenticityAuthentication: "Reproduction — not to be confused with period originals."
        ),
        Antique(
            name: "Antique Japanese Moriage Vase",
            shortTitle: "Moriage Vase",
            yearMade: 1910,
            category: .ceramics,
            subcategory: "Vase",
            style: "Meiji",
            origin: "Japan",
            maker: "Nippon-era studio",
            valueRange: AntiqueValueRange(low: 80, high: 250),
            estimatedValue: 150,
            aiConfidence: 0.90,
            itemIdentification: "Japanese Nippon-era vase with moriage (slip-trail) relief floral decoration, hand-painted enamels.",
            datingAge: "Circa 1910, Meiji/Nippon period.",
            originProvenance: "Japanese export porcelain market.",
            materialsConstruction: "Porcelain with slip-trailed raised decoration and polychrome enamels.",
            physicalCharacteristics: "Approximately 9-12 inches tall.",
            conditionAssessment: "Check for chips along rim and moriage losses.",
            valuation: "Retail $80-$250; signed examples higher.",
            raritySignificance: "Collectible category with steady demand.",
            authenticityAuthentication: "Examine base for Nippon / Hand-Painted Nippon marks."
        ),
        Antique(
            name: "Floral Ceramic Vase with Gilt",
            shortTitle: "Floral Vase",
            yearMade: 1895,
            category: .ceramics,
            subcategory: "Vase",
            style: "Victorian",
            origin: "Bohemia",
            maker: "Unmarked",
            valueRange: AntiqueValueRange(low: 60, high: 200),
            estimatedValue: 110,
            aiConfidence: 0.78,
            itemIdentification: "Polychrome floral decoration with gilt accents on white ground.",
            datingAge: "Late Victorian, circa 1895.",
            originProvenance: "Bohemian or German porcelain house.",
            materialsConstruction: "Hard-paste porcelain with overglaze enamels and gilding.",
            physicalCharacteristics: "Baluster form, approximately 12 inches tall.",
            conditionAssessment: "Gilding wear is common; examine rim and foot for chips.",
            valuation: "Retail $60-$200 depending on condition and maker.",
            raritySignificance: "Plentiful category; maker-marked examples trend higher.",
            authenticityAuthentication: "Consider base marks and glaze characteristics."
        ),
        Antique(
            name: "Antique Folding Bed Campaign Chest",
            shortTitle: "Folding Chest",
            yearMade: 1870,
            category: .furniture,
            subcategory: "Campaign Chest",
            style: "Victorian Campaign",
            origin: "England",
            maker: "Unknown",
            valueRange: AntiqueValueRange(low: 600, high: 1800),
            estimatedValue: 1100,
            aiConfidence: 0.81,
            itemIdentification: "Brass-bound campaign-style chest with folding mechanism.",
            datingAge: "Circa 1870, Victorian campaign furniture era.",
            originProvenance: "British colonial-era production.",
            materialsConstruction: "Mahogany or teak with brass corners and recessed handles.",
            physicalCharacteristics: "Two-part construction; typical 36-40 inches wide.",
            conditionAssessment: "Check brassware completeness and structural integrity of hinges.",
            valuation: "Retail $600-$1,800 depending on condition and timber.",
            raritySignificance: "Sought after by interior designers; good market.",
            authenticityAuthentication: "Hand-cut dovetails and oxidized brass support period origin."
        ),
        Antique(
            name: "Novelty Teapot Clock",
            shortTitle: "Teapot Clock",
            yearMade: 1935,
            category: .clocks,
            subcategory: "Novelty Clock",
            style: "Art Deco",
            origin: "USA",
            maker: "Unknown",
            valueRange: AntiqueValueRange(low: 75, high: 225),
            estimatedValue: 140,
            aiConfidence: 0.84,
            itemIdentification: "Ceramic teapot-form clock with integrated dial.",
            datingAge: "Circa 1930s novelty production.",
            originProvenance: "American kitchen-ware crossover.",
            materialsConstruction: "Glazed earthenware body, mechanical or electric movement.",
            physicalCharacteristics: "Shelf-scale novelty piece.",
            conditionAssessment: "Glaze crazing common; working movement adds value.",
            valuation: "Retail $75-$225.",
            raritySignificance: "Plentiful; collectors seek unusual forms.",
            authenticityAuthentication: "Period-consistent glaze and movement."
        )
    ]
}
