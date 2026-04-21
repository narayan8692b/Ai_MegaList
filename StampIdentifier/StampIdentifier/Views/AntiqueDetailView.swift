import SwiftUI

struct AntiqueDetailView: View {
    @EnvironmentObject private var store: AntiqueStore
    @Environment(\.dismiss) private var dismiss

    let antique: Antique
    var showsAddButton: Bool = false

    @State private var expanded: Set<AntiqueSection> = [.itemIdentification]
    @State private var didAdd = false

    enum AntiqueSection: String, CaseIterable, Identifiable, Hashable {
        case itemIdentification     = "Item Identification"
        case datingAge              = "Dating & Age"
        case originProvenance       = "Origin & Provenance"
        case materialsConstruction  = "Materials & Construction"
        case physicalCharacteristics = "Physical Characteristics"
        case conditionAssessment    = "Condition Assessment"
        case valuation              = "Valuation"
        case raritySignificance     = "Rarity & Significance"
        case authenticity           = "Authenticity & Authentication"

        var id: String { rawValue }

        var systemImage: String {
            switch self {
            case .itemIdentification:      return "info.circle"
            case .datingAge:               return "clock"
            case .originProvenance:        return "mappin.and.ellipse"
            case .materialsConstruction:   return "wrench.and.screwdriver"
            case .physicalCharacteristics: return "ruler"
            case .conditionAssessment:     return "checkmark.seal"
            case .valuation:               return "dollarsign.circle"
            case .raritySignificance:      return "star"
            case .authenticity:            return "checkmark.shield"
            }
        }
    }

    var body: some View {
        ZStack {
            Color.antiqueCream.ignoresSafeArea()
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
        .navigationTitle("Antique Details")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            if showsAddButton { addButton.padding(.horizontal).padding(.bottom, 12) }
        }
    }

    // MARK: Subviews

    private var heroImage: some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if let data = antique.imageData, let image = UIImage(data: data) {
                    Image(uiImage: image).resizable().scaledToFit()
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.05))
                        .frame(height: 220)
                        .overlay {
                            Image(systemName: "crown")
                                .font(.system(size: 48))
                                .foregroundStyle(Color.antiqueGold)
                        }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                Text("AI conf.: \(Int(antique.aiConfidence * 100))%")
            }
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(Capsule().fill(Color.antiqueGold))
            .foregroundStyle(.white)
            .padding(10)
        }
    }

    private var valueCard: some View {
        VStack(spacing: 10) {
            Text(antique.name)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.brandInk)

            HStack(spacing: 8) {
                Text(antique.shortTitle.uppercased())
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                if let year = antique.yearMade {
                    Text("\(String(year))")
                        .font(.footnote.weight(.regular))
                        .foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(Color.brandInk)

            Text(antique.valueRange.displayRange)
                .font(.system(.title3, design: .rounded, weight: .heavy))
                .foregroundStyle(.white)
                .padding(.vertical, 10)
                .padding(.horizontal, 24)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.antiqueGold)
                )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }

    private var metadataCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            labelledRow(icon: "tag", title: "Category", value: antique.category.rawValue)
            Divider()
            labelledRow(icon: "rectangle.stack", title: "Subcategory", value: antique.subcategory)
            Divider()
            labelledRow(icon: "paintpalette", title: "Style", value: antique.style)
            Divider()
            labelledRow(icon: "calendar", title: "Year Made", value: antique.yearDisplay)
            Divider()
            labelledRow(icon: "flag", title: "Origin", value: antique.origin)
            if !antique.maker.isEmpty {
                Divider()
                labelledRow(icon: "person", title: "Maker / Attribution", value: antique.maker)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }

    private var sectionsCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(AntiqueSection.allCases.enumerated()), id: \.element) { index, section in
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
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)
                        .padding(.bottom, 4)
                } label: {
                    Label(section.rawValue, systemImage: section.systemImage)
                        .font(.headline)
                        .foregroundStyle(Color.brandInk)
                        .padding(.vertical, 8)
                }
                .tint(Color.antiqueGold)
                .padding(.horizontal, 16)

                if index < AntiqueSection.allCases.count - 1 {
                    Divider().padding(.horizontal, 16)
                }
            }
        }
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }

    private var addButton: some View {
        Button {
            store.add(antique)
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
        .tint(Color.antiqueGold)
        .controlSize(.large)
        .disabled(didAdd)
    }

    // MARK: Helpers

    private func labelledRow(icon: String, title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: icon)
                .frame(width: 22)
                .foregroundStyle(Color.antiqueGold)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.brandInk)
            }
            Spacer()
        }
    }

    private func content(for section: AntiqueSection) -> String {
        switch section {
        case .itemIdentification:      return antique.itemIdentification
        case .datingAge:               return antique.datingAge
        case .originProvenance:        return antique.originProvenance
        case .materialsConstruction:   return antique.materialsConstruction
        case .physicalCharacteristics: return antique.physicalCharacteristics
        case .conditionAssessment:     return antique.conditionAssessment
        case .valuation:               return antique.valuation
        case .raritySignificance:      return antique.raritySignificance
        case .authenticity:            return antique.authenticityAuthentication
        }
    }
}

#Preview {
    NavigationStack {
        AntiqueDetailView(antique: .sampleBronzeVase, showsAddButton: true)
            .environmentObject(AntiqueStore())
    }
}
