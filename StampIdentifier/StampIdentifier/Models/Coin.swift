import Foundation

enum CoinMaterial: String, Codable, CaseIterable, Identifiable, Hashable {
    case gold     = "Gold"
    case silver   = "Silver"
    case copper   = "Copper"
    case bronze   = "Bronze"
    case nickel   = "Nickel"
    case bimetal  = "Bi-metal"
    case alloy    = "Alloy"
    case unknown  = "Unknown"

    var id: String { rawValue }
}

struct CoinValueRange: Codable, Hashable {
    var low: Double
    var high: Double

    var displayRange: String {
        let lo = CurrencyFormatter.usd.string(from: NSNumber(value: low)) ?? "$\(Int(low))"
        let hi = CurrencyFormatter.usd.string(from: NSNumber(value: high)) ?? "$\(Int(high))"
        return "\(lo) - \(hi)"
    }
}

struct Coin: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var shortTitle: String
    var yearMinted: Int?
    var country: String
    var type: String                // e.g. "Foreign Coin", "Commemorative"
    var denomination: String
    var materials: String           // e.g. "Gold (Likely)", "Silver 90%"
    var mintMark: String
    var estimatedValue: Double
    var valueRange: CoinValueRange
    var aiConfidence: Double

    // Detail sections from the Identification Details screenshot
    var historicalContext: String
    var technicalDetails: String
    var conditionGrading: String
    var marketInvestment: String
    var foreignCoinDetails: String
    var educationalContent: String
    var personalization: String
    var socialSharing: String

    var imageData: Data?
    var dateAdded: Date = Date()

    var yearDisplay: String { yearMinted.map(String.init) ?? "Unknown" }
}

extension Coin {
    static let sampleGoldCoin1876 = Coin(
        name: "Unidentified Gold Coin",
        shortTitle: "Gold Coin",
        yearMinted: 1876,
        country: "Unknown",
        type: "Foreign Coin",
        denomination: "Unknown",
        materials: "Gold (Likely)",
        mintMark: "",
        estimatedValue: 3000,
        valueRange: CoinValueRange(low: 2000, high: 4000),
        aiConfidence: 0.75,
        historicalContext: "The 1876 date places this coin in the last quarter of the 19th century, a period of rapid industrial expansion and shifts in international coinage. The style of lettering and figural relief suggests European origin, but the absence of a legible country mark prevents firm attribution.",
        technicalDetails: "Diameter appears to be approximately 22-28mm based on photographic scale. Reeded edge is partially visible. Surfaces show yellow-gold tone consistent with .900 or higher fineness. No evidence of cleaning or tooling.",
        conditionGrading: "Approximate grade VF-XF (Very Fine to Extremely Fine). Legends are readable, high points show modest wear, and the overall strike retains good detail. Tooling specialist review recommended.",
        marketInvestment: "Unattributed gold coins of this weight class typically trade at a modest premium over melt. If the coin is identified and rarity confirmed, numismatic value could exceed bullion value by 2-5x.",
        foreignCoinDetails: "Imagery suggests European origin — candidates include Italian Lira, French Franc, or Ottoman sovereign. A comparison of the ruler's profile with period issues will narrow attribution.",
        educationalContent: "Foreign gold coins from the 1860s-1880s were produced to the Latin Monetary Union standard in much of continental Europe. Weight and fineness are often consistent across issuing nations.",
        personalization: "Add this coin to your collection to track changes in its spot-melt value and estimated numismatic premium over time.",
        socialSharing: "Share this identification to invite community attribution. Numismatic collectors can often identify obscure issues in minutes."
    )

    static let seedCollection: [Coin] = [
        Coin(
            name: "Foreign Coin",
            shortTitle: "Foreign Coin",
            yearMinted: 1890,
            country: "Unidentified",
            type: "Foreign Coin",
            denomination: "Unknown",
            materials: "Gold (Likely)",
            mintMark: "",
            estimatedValue: 500,
            valueRange: CoinValueRange(low: 200, high: 800),
            aiConfidence: 0.72,
            historicalContext: "Late 19th century foreign issue.",
            technicalDetails: "Circular, reeded edge, approximately 22mm diameter.",
            conditionGrading: "Fine (F-VF) grade based on wear patterns.",
            marketInvestment: "Spot-plus premium.",
            foreignCoinDetails: "Origin unclear — European or Latin American.",
            educationalContent: "",
            personalization: "",
            socialSharing: ""
        ),
        Coin(
            name: "Saint-Gaudens gold coin",
            shortTitle: "gold coin",
            yearMinted: 1907,
            country: "USA",
            type: "US Gold",
            denomination: "$20 Double Eagle",
            materials: "Gold 90%",
            mintMark: "",
            estimatedValue: 2800,
            valueRange: CoinValueRange(low: 2400, high: 3400),
            aiConfidence: 0.94,
            historicalContext: "Saint-Gaudens Double Eagle, designed by Augustus Saint-Gaudens.",
            technicalDetails: "34mm diameter, 33.4g gross weight, .900 fine gold.",
            conditionGrading: "Circulated XF-AU grade.",
            marketInvestment: "Bullion + strong numismatic premium; steady market.",
            foreignCoinDetails: "",
            educationalContent: "Introduced 1907, widely regarded as the most beautiful US coin.",
            personalization: "",
            socialSharing: ""
        ),
        Coin(
            name: "Euro coin",
            shortTitle: "Euro coin",
            yearMinted: 2002,
            country: "Eurozone",
            type: "Commemorative",
            denomination: "2 Euro",
            materials: "Bi-metal",
            mintMark: "",
            estimatedValue: 4,
            valueRange: CoinValueRange(low: 2, high: 8),
            aiConfidence: 0.96,
            historicalContext: "Circulating euro coin issued from 2002.",
            technicalDetails: "25.75mm diameter, nickel-brass / cupro-nickel bi-metal.",
            conditionGrading: "Uncirculated to circulated.",
            marketInvestment: "Face value with occasional commemorative premiums.",
            foreignCoinDetails: "Issuing country visible on national side.",
            educationalContent: "",
            personalization: "",
            socialSharing: ""
        ),
        Coin(
            name: "Italian foreign coin",
            shortTitle: "foreign coin",
            yearMinted: 1903,
            country: "Italy",
            type: "Foreign Coin",
            denomination: "10 Centesimi",
            materials: "Copper",
            mintMark: "R",
            estimatedValue: 15,
            valueRange: CoinValueRange(low: 5, high: 40),
            aiConfidence: 0.80,
            historicalContext: "Early 20th century Italian copper coinage under Vittorio Emanuele III.",
            technicalDetails: "30mm diameter, copper composition.",
            conditionGrading: "Fine-VF.",
            marketInvestment: "Modest collector market.",
            foreignCoinDetails: "Royal profile identifies ruler.",
            educationalContent: "",
            personalization: "",
            socialSharing: ""
        ),
        Coin(
            name: "Sierra Leone leone",
            shortTitle: "Sierra Leone",
            yearMinted: 1964,
            country: "Sierra Leone",
            type: "Commemorative",
            denomination: "1 Leone",
            materials: "Silver",
            mintMark: "",
            estimatedValue: 18,
            valueRange: CoinValueRange(low: 8, high: 35),
            aiConfidence: 0.87,
            historicalContext: "Post-independence silver commemorative issue.",
            technicalDetails: "30mm silver coin featuring national emblem.",
            conditionGrading: "Circulated VF.",
            marketInvestment: "African commemorative market steady.",
            foreignCoinDetails: "Sierra Leone independence commemorative.",
            educationalContent: "",
            personalization: "",
            socialSharing: ""
        ),
        Coin(
            name: "Elizabeth II silver coin",
            shortTitle: "foreign coin",
            yearMinted: 1953,
            country: "Great Britain",
            type: "Foreign Coin",
            denomination: "Half Crown",
            materials: "Silver",
            mintMark: "",
            estimatedValue: 9,
            valueRange: CoinValueRange(low: 3, high: 20),
            aiConfidence: 0.86,
            historicalContext: "Coronation-year coinage of Elizabeth II.",
            technicalDetails: "32mm cupro-nickel half crown.",
            conditionGrading: "F-VF circulated.",
            marketInvestment: "Low premium.",
            foreignCoinDetails: "Common British circulating issue.",
            educationalContent: "",
            personalization: "",
            socialSharing: ""
        )
    ]
}
