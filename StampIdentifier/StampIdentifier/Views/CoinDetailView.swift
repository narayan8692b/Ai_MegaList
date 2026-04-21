import SwiftUI

struct CoinDetailView: View {
    @EnvironmentObject private var store: CoinStore
    @Environment(\.dismiss) private var dismiss

    let coin: Coin
    var showsAddButton: Bool = false

    @State private var didAdd = false
    @State private var expanded: Set<CoinSection> = [.historical]

    enum CoinSection: String, CaseIterable, Identifiable, Hashable {
        case historical   = "Historical Context"
        case technical    = "Technical Details"
        case condition    = "Condition & Grading"
        case market       = "Market & Investment"
        case foreign      = "Foreign coin Details"
        case educational  = "Educational Content"
        case personal     = "Personalization"
        case social       = "Social & Sharing"

        var id: String { rawValue }

        var systemImage: String {
            switch self {
            case .historical:  return "clock.arrow.circlepath"
            case .technical:   return "wrench.and.screwdriver"
            case .condition:   return "chart.bar"
            case .market:      return "chart.line.uptrend.xyaxis"
            case .foreign:     return "globe"
            case .educational: return "graduationcap"
            case .personal:    return "person.crop.circle"
            case .social:      return "square.and.arrow.up"
            }
        }
    }

    var body: some View {
        ZStack {
            Color.coinCream.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    heroImage
                    valueCard
                    metadataCard
                    sectionsCard
                }
                .padding(.vertical, 16)
                .padding(.horizontal)
            }
        }
        .navigationTitle("Identification Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            if showsAddButton { addButton.padding(.horizontal).padding(.bottom, 12) }
        }
    }

    // MARK: Subviews

    private var heroImage: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if let data = coin.imageData, let image = UIImage(data: data) {
                    Image(uiImage: image).resizable().scaledToFit()
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.coinGold.opacity(0.12))
                        Image(systemName: "dollarsign.circle")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.coinGold)
                    }
                    .frame(height: 220)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            HStack(spacing: 5) {
                Image(systemName: "sparkles")
                Text("AI Conf.: \(Int(coin.aiConfidence * 100))%")
            }
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(Color.coinGold))
            .foregroundStyle(.black)
            .padding(10)
        }
    }

    private var valueCard: some View {
        VStack(spacing: 10) {
            Text(coin.shortTitle.uppercased())
                .font(.system(.title2, design: .rounded, weight: .heavy))
                .foregroundStyle(.white) +
            Text(coin.yearMinted.map { " \($0)" } ?? "")
                .font(.system(.callout, design: .rounded, weight: .regular))
                .foregroundStyle(.white.opacity(0.7))

            Text(coin.valueRange.displayRange)
                .font(.system(.title3, design: .rounded, weight: .heavy))
                .foregroundStyle(.black)
                .padding(.vertical, 10)
                .padding(.horizontal, 24)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.coinGold)
                )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
    }

    private var metadataCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            row(icon: "dollarsign", title: "Type", value: coin.type)
            Divider().background(Color.white.opacity(0.1))
            row(icon: "number", title: "Denomination", value: coin.denomination)
            Divider().background(Color.white.opacity(0.1))
            row(icon: "hammer", title: "Materials", value: coin.materials)
            Divider().background(Color.white.opacity(0.1))
            row(icon: "calendar", title: "Year", value: coin.yearDisplay)
            Divider().background(Color.white.opacity(0.1))
            row(icon: "flag", title: "Country", value: coin.country)
            if !coin.mintMark.isEmpty {
                Divider().background(Color.white.opacity(0.1))
                row(icon: "location.square", title: "Mint Mark", value: coin.mintMark)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
    }

    private func row(icon: String, title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(Color.coinGold)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.65))
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
            }
            Spacer()
        }
    }

    private var sectionsCard: some View {
        VStack(spacing: 10) {
            ForEach(CoinSection.allCases) { section in
                DisclosureGroup(
                    isExpanded: Binding(
                        get: { expanded.contains(section) },
                        set: { isOn in
                            if isOn { expanded.insert(section) } else { expanded.remove(section) }
                        }
                    )
                ) {
                    Text(content(for: section))
                        .font(.subheadline)
                        .foregroundStyle(Color.brandInk)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)
                } label: {
                    Label(section.rawValue, systemImage: section.systemImage)
                        .font(.headline)
                        .foregroundStyle(Color.brandInk)
                        .padding(.vertical, 4)
                }
                .tint(Color.coinGold)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white)
                )
            }
        }
    }

    private var addButton: some View {
        Button {
            store.add(coin)
            didAdd = true
            dismiss()
        } label: {
            Label(didAdd ? "Added to Collection" : "Add to Collection",
                  systemImage: didAdd ? "checkmark.circle.fill" : "plus.circle.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .tint(Color.coinGold)
        .controlSize(.large)
        .disabled(didAdd)
    }

    private func content(for section: CoinSection) -> String {
        switch section {
        case .historical:  return coin.historicalContext
        case .technical:   return coin.technicalDetails
        case .condition:   return coin.conditionGrading
        case .market:      return coin.marketInvestment
        case .foreign:     return coin.foreignCoinDetails
        case .educational: return coin.educationalContent.isEmpty
            ? "Coins of this era are documented across numismatic catalogs — Krause, Spink, and Yeoman are good references."
            : coin.educationalContent
        case .personal:    return coin.personalization.isEmpty
            ? "Add this coin to your collection to track spot-melt value and numismatic premium over time."
            : coin.personalization
        case .social:      return coin.socialSharing.isEmpty
            ? "Share this identification with the community for attribution help."
            : coin.socialSharing
        }
    }
}

#Preview {
    NavigationStack {
        CoinDetailView(coin: .sampleGoldCoin1876, showsAddButton: true)
            .environmentObject(CoinStore())
    }
}
