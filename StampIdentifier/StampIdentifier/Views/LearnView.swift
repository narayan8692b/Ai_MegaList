import SwiftUI

struct LearnView: View {
    @AppStorage("selectedMode") private var storedMode: String = CollectibleMode.stamp.rawValue

    private var mode: CollectibleMode {
        CollectibleMode(rawValue: storedMode) ?? .stamp
    }

    private var topics: [LearnTopic] {
        mode == .stamp ? LearnTopic.stampTopics : LearnTopic.antiqueTopics
    }

    var body: some View {
        NavigationStack {
            ZStack {
                (mode == .stamp ? Color.brandCream : Color.antiqueCream)
                    .ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        modeSwitcher
                        header
                        ForEach(topics) { topic in
                            NavigationLink {
                                LearnDetailView(topic: topic, accent: mode.accentColor)
                            } label: {
                                topicCard(topic)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Learn")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var modeSwitcher: some View {
        Picker("Mode", selection: $storedMode) {
            ForEach(CollectibleMode.allCases) { m in
                Text(m.rawValue).tag(m.rawValue)
            }
        }
        .pickerStyle(.segmented)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(mode == .stamp ? "Everything About Stamps" : "Everything About Antiques")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(Color.brandInk)
            Text(mode == .stamp
                 ? "Short guides to help you identify, grade, and value any stamp."
                 : "Short guides to help you identify, date, and value vintage items.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
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
}

struct LearnDetailView: View {
    let topic: LearnTopic
    var accent: Color = .brandOrange

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: topic.systemImage)
                        .font(.title)
                        .foregroundStyle(accent)
                    Text(topic.title)
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(Color.brandInk)
                }
                Text(topic.body)
                    .font(.body)
                    .foregroundStyle(Color.brandInk)
                Spacer(minLength: 0)
            }
            .padding()
        }
        .background(Color.brandCream.ignoresSafeArea())
        .navigationTitle(topic.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    LearnView()
}
