import SwiftUI

struct LearnView: View {
    @AppStorage("selectedMode") private var storedMode: String = CollectibleMode.stamp.rawValue

    private var mode: CollectibleMode {
        CollectibleMode(rawValue: storedMode) ?? .stamp
    }

    private var topics: [LearnTopic] {
        switch mode {
        case .stamp:   return LearnTopic.stampTopics
        case .antique: return LearnTopic.antiqueTopics
        case .jewelry: return LearnTopic.jewelryTopics
        case .coin:    return LearnTopic.coinTopics
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                mode.backgroundColor.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ModeChipPicker(selection: $storedMode)
                        header
                            .padding(.horizontal, 16)
                        VStack(spacing: 12) {
                            ForEach(topics) { topic in
                                NavigationLink {
                                    LearnDetailView(topic: topic, accent: mode.accentColor,
                                                    background: mode.backgroundColor,
                                                    textColor: mode == .coin ? .white : Color.brandInk)
                                } label: {
                                    topicCard(topic)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Learn")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(mode == .coin ? .dark : .light, for: .navigationBar)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(headerTitle)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(mode == .coin ? .white : Color.brandInk)
            Text(headerSubtitle)
                .font(.subheadline)
                .foregroundStyle(mode == .coin ? Color.white.opacity(0.7) : .secondary)
        }
    }

    private var headerTitle: String {
        switch mode {
        case .stamp:   return "Everything About Stamps"
        case .antique: return "Everything About Antiques"
        case .jewelry: return "Everything About Jewelry"
        case .coin:    return "Everything About Coins"
        }
    }

    private var headerSubtitle: String {
        "Short guides to help you identify, grade, and value any \(mode.singular.lowercased())."
    }

    private func topicCard(_ topic: LearnTopic) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(mode.accentColor.opacity(0.15))
                Image(systemName: topic.systemImage)
                    .font(.title3)
                    .foregroundStyle(mode.accentColor)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 2) {
                Text(topic.title)
                    .font(.headline)
                    .foregroundStyle(Color.brandInk)
                Text(topic.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        )
    }
}

struct LearnTopic: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
    let systemImage: String
    let body: String

    static let stampTopics: [LearnTopic] = [
        LearnTopic(
            title: "Catalog Numbers",
            subtitle: "How Stanley Gibbons, Scott, Michel, and Yvert classify stamps.",
            systemImage: "number",
            body: "Stamps are catalogued by issuing country and chronology. The major catalogues — Stanley Gibbons (UK), Scott (US), Michel (DE), and Yvert & Tellier (FR) — each assign their own number. Cross-referencing catalogues is common when valuing international issues."
        ),
        LearnTopic(
            title: "Grading & Condition",
            subtitle: "Centering, gum, cancellations, and faults.",
            systemImage: "checkmark.seal",
            body: "Condition drives value. Collectors grade on centering, freshness of color, quality of perforations, gum (for unused stamps), and clarity of cancellation (for used). Faults like thins, tears, or creases reduce value significantly."
        ),
        LearnTopic(
            title: "Watermarks & Perforations",
            subtitle: "Subtle varieties that change the catalog entry.",
            systemImage: "magnifyingglass",
            body: "Watermarks are patterns embedded in paper, visible against light or with watermark fluid. Perforation gauges measure teeth per 2 cm. Small variations can distinguish common issues from major rarities."
        ),
        LearnTopic(
            title: "Storing Your Collection",
            subtitle: "Albums, stockbooks, and archival sleeves.",
            systemImage: "folder",
            body: "Store stamps away from light, humidity, and heat. Use acid-free mounts and albums. Avoid taping, gluing, or hinging valuable mint stamps — use transparent mounts that preserve original gum."
        ),
        LearnTopic(
            title: "Selling & Authentication",
            subtitle: "Certificates, auctions, and dealer networks.",
            systemImage: "doc.text.magnifyingglass",
            body: "For high-value stamps, a certificate from a recognized expert body (RPSL, PF, BPA) reassures buyers. Major auction houses specialize in philately and often achieve the strongest prices for rarities."
        )
    ]

    static let antiqueTopics: [LearnTopic] = [
        LearnTopic(
            title: "Dating & Age",
            subtitle: "Period, circa, and age-dating clues.",
            systemImage: "clock",
            body: "Dating relies on style, construction, materials, and provenance. 'Circa' (c.) indicates an approximate decade; 'period' denotes a named era (Georgian, Victorian, Art Nouveau, Art Deco). Hardware, joinery, and wear patterns are often more reliable than style alone."
        ),
        LearnTopic(
            title: "Origin & Provenance",
            subtitle: "Tracing an item's country, maker, and history of ownership.",
            systemImage: "mappin.and.ellipse",
            body: "Provenance is the documented history of ownership. A clear chain of ownership — receipts, estate records, auction lots — significantly affects value. Marks, stamps, and signatures help attribute an item to a country or maker."
        ),
        LearnTopic(
            title: "Materials & Construction",
            subtitle: "Wood, metal, ceramic, glass, and their tells.",
            systemImage: "wrench.and.screwdriver",
            body: "Hand-cut dovetails, cast-iron hardware, slip-trailed enamels, mouth-blown glass — construction techniques reveal both era and regional origin. Reproductions often reveal themselves through machine uniformity or modern adhesives."
        ),
        LearnTopic(
            title: "Condition Grading",
            subtitle: "How restoration, wear, and faults affect value.",
            systemImage: "checkmark.seal",
            body: "Most categories use grades from Mint / Excellent down to Fair / Poor. Original surfaces, finishes, and patinas are preferred. Sympathetic conservation is acceptable; heavy restoration usually reduces value."
        ),
        LearnTopic(
            title: "Authenticity",
            subtitle: "Marks, materials, and expert opinions.",
            systemImage: "checkmark.shield",
            body: "Look for maker's marks, hallmarks, and signatures. Materials should be consistent with the attributed date. For high-value items, seek an expert opinion from an auction specialist or recognised appraiser before purchase or sale."
        ),
        LearnTopic(
            title: "Valuation & Selling",
            subtitle: "Fair market value vs retail replacement.",
            systemImage: "dollarsign.circle",
            body: "Fair Market Value (FMV) is what a willing buyer pays in an open market. Replacement value is higher — typically used for insurance. Compare recent auction results in the same category for the most realistic estimate."
        )
    ]

    static let jewelryTopics: [LearnTopic] = [
        LearnTopic(
            title: "Metal Karats & Purity",
            subtitle: "10K, 14K, 18K, 22K, 24K — what the stamps mean.",
            systemImage: "circle.grid.cross",
            body: "Karat indicates gold purity out of 24. 14K = 58.5% gold (stamped 585); 18K = 75% (750); 22K = 91.6% (916); 24K = pure. Silver is typically 925 (sterling). Platinum is 950 (PT950). Stamps are usually inside rings or on clasps."
        ),
        LearnTopic(
            title: "Gemstone Grading",
            subtitle: "The four Cs for diamonds — and what applies to colored stones.",
            systemImage: "diamond",
            body: "Diamonds are graded on Carat, Clarity (VVS-I), Color (D-Z), and Cut. Colored stones weigh carat and color saturation most heavily. Lab-grown diamonds are chemically identical but carry a lower market premium."
        ),
        LearnTopic(
            title: "Hallmarks & Maker's Marks",
            subtitle: "How to read a ring's interior.",
            systemImage: "signature",
            body: "Inside most rings you'll find a purity mark (e.g. 750) plus a maker's mark or trademark. British, French, Italian, and Russian hallmarking systems each use distinct symbols — country marks, date letters, and assay-office stamps."
        ),
        LearnTopic(
            title: "Condition & Restoration",
            subtitle: "Rhodium plating, prong retipping, stone loss.",
            systemImage: "checkmark.seal",
            body: "Small restorations (polishing, retipping prongs, rhodium plating on white gold) are normal and don't reduce value materially. Heavy restoration, stone replacement, or modern shank additions to antique pieces do reduce value."
        ),
        LearnTopic(
            title: "Selling & Market Channels",
            subtitle: "Dealers vs. auction vs. online resale.",
            systemImage: "cart",
            body: "Dealers offer fastest liquidity at 40-60% of retail. Auction can achieve stronger prices for rare / signed pieces but takes months and involves seller's premium. Online platforms (eBay, 1stDibs, Etsy) hit the broadest buyer pool."
        ),
        LearnTopic(
            title: "Insurance & Appraisals",
            subtitle: "Replacement value vs fair market value.",
            systemImage: "shield",
            body: "Insurance appraisals are typically retail replacement value. Estate / donation appraisals use fair market value. Keep a dated appraisal on file with photos; update every 3-5 years as metal and stone markets shift."
        )
    ]

    static let coinTopics: [LearnTopic] = [
        LearnTopic(
            title: "Historical Context",
            subtitle: "Place a coin in its economic and political era.",
            systemImage: "clock.arrow.circlepath",
            body: "Coins reflect the politics, economics, and metallurgy of their issuers. Understanding the era — rulers, wars, currency reforms — helps attribute unlisted foreign issues and explain design choices."
        ),
        LearnTopic(
            title: "Technical Details",
            subtitle: "Diameter, weight, composition, edge.",
            systemImage: "wrench.and.screwdriver",
            body: "Technical specs are the fastest route to attribution. Use a calliper and a 0.01g scale. Note the edge — reeded, plain, lettered, or decorated — since the same design can appear on multiple edge types, changing catalog value dramatically."
        ),
        LearnTopic(
            title: "Condition & Grading",
            subtitle: "Poor through MS-70.",
            systemImage: "chart.bar",
            body: "Grading scales run from P-1 (Poor) through AG, G, VG, F, VF, EF, AU, MS. MS coins are graded MS-60 through MS-70. Cleaning, whizzing, and harsh polish are detriments; original patinas are preferred."
        ),
        LearnTopic(
            title: "Market & Investment",
            subtitle: "Spot, numismatic, and condition premiums.",
            systemImage: "chart.line.uptrend.xyaxis",
            body: "Market value combines intrinsic (metal) value, numismatic scarcity premium, and grade premium. Bullion coins track spot; collectible coins have a higher numismatic premium that depends on rarity and preservation."
        ),
        LearnTopic(
            title: "Foreign Coin Details",
            subtitle: "Identifying issuer country from a single face.",
            systemImage: "globe",
            body: "Ruler portraits, language, alphabet, religious symbols, and denominations are strong clues. The Latin Monetary Union (1865-1927) harmonised weights across continental Europe — useful when attributing undated gold issues."
        ),
        LearnTopic(
            title: "Authentication & Counterfeits",
            subtitle: "Tests for metal, weight, and die characteristics.",
            systemImage: "checkmark.shield",
            body: "Weigh, measure, and magnify. XRF testing confirms metal composition non-destructively. Die studies identify contemporary fakes from their distinctive die marks. For valuable coins, third-party grading (PCGS, NGC) provides guaranteed authentication."
        )
    ]
}

struct LearnDetailView: View {
    let topic: LearnTopic
    var accent: Color = .brandOrange
    var background: Color = .brandCream
    var textColor: Color = .brandInk

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: topic.systemImage)
                        .font(.title)
                        .foregroundStyle(accent)
                    Text(topic.title)
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(textColor)
                }
                Text(topic.body)
                    .font(.body)
                    .foregroundStyle(textColor)
                Spacer(minLength: 0)
            }
            .padding()
        }
        .background(background.ignoresSafeArea())
        .navigationTitle(topic.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    LearnView()
}
