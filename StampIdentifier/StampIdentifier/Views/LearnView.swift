import SwiftUI

struct LearnView: View {
    private let topics: [LearnTopic] = LearnTopic.allTopics

    var body: some View {
        NavigationStack {
            ZStack {
                Color.brandCream.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        header
                        ForEach(topics) { topic in
                            NavigationLink {
                                LearnDetailView(topic: topic)
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

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Everything About Stamps")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(Color.brandInk)
            Text("Short guides to help you identify, grade, and value any stamp.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func topicCard(_ topic: LearnTopic) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.brandOrange.opacity(0.15))
                Image(systemName: topic.systemImage)
                    .font(.title3)
                    .foregroundStyle(Color.brandOrange)
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

    static let allTopics: [LearnTopic] = [
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
}

struct LearnDetailView: View {
    let topic: LearnTopic

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: topic.systemImage)
                        .font(.title)
                        .foregroundStyle(Color.brandOrange)
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
