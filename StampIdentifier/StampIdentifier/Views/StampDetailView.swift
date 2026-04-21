import SwiftUI

struct StampDetailView: View {
    @EnvironmentObject private var store: StampStore
    @Environment(\.dismiss) private var dismiss

    let stamp: Stamp
    var showsAddButton: Bool = false

    @State private var expandedSections: Set<DetailSection> = [.description]
    @State private var didAdd = false

    enum DetailSection: String, CaseIterable, Identifiable {
        case description = "Description"
        case physical = "Physical Analysis"
        case historical = "Historical Context"
        case value = "Value Analysis"
        case collector = "Collector Info"

        var id: String { rawValue }
        var systemImage: String {
            switch self {
            case .description: return "info.circle"
            case .physical:    return "magnifyingglass"
            case .historical:  return "book.closed"
            case .value:       return "dollarsign.circle"
            case .collector:   return "person.crop.circle.badge.checkmark"
            }
        }
    }

    var body: some View {
        ZStack {
            Color.brandCream.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    heroImage
                    nameAndValueCard
                    metadataCard
                    notesCard
                    sectionsCard
                }
                .padding(.vertical, 16)
                .padding(.horizontal)
            }
        }
        .navigationTitle("Stamp Details")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            if showsAddButton {
                addButton
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                    .background(Color.brandCream.opacity(0.95))
            }
        }
    }

    // MARK: Sections

    private var heroImage: some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if let data = stamp.imageData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.05))
                        .overlay {
                            Image(systemName: "photo")
                                .font(.system(size: 48))
                                .foregroundStyle(.secondary)
                        }
                        .frame(height: 220)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            ConfidencePill(confidence: stamp.aiConfidence)
                .padding(10)
        }
    }

    private var nameAndValueCard: some View {
        VStack(spacing: 10) {
            Text(stamp.name)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.brandInk)
            Text(valueDisplay)
                .font(.system(.title, design: .rounded, weight: .heavy))
                .foregroundStyle(Color.brandOrange)
                .padding(.vertical, 10)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.brandOrange.opacity(0.08))
                )
            HStack(spacing: 8) {
                RarityBadge(rarity: stamp.rarity)
                Text(stamp.valueRange.displayRange)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
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
            labelledRow(icon: "number", title: "Catalog Number", value: stamp.catalogNumbersDisplay)
            Divider()
            labelledRow(icon: "flag", title: "Country", value: stamp.country)
            Divider()
            labelledRow(icon: "calendar", title: "Year Issued", value: stamp.yearDisplay)
            Divider()
            labelledRow(icon: "tag", title: "Denomination", value: stamp.denomination)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }

    private var notesCard: some View {
        guard !stamp.additionalNotes.isEmpty else { return AnyView(EmptyView()) }
        return AnyView(
            VStack(alignment: .leading, spacing: 8) {
                Label("Additional Notes", systemImage: "note.text")
                    .font(.headline)
                    .foregroundStyle(Color.brandInk)
                Text(stamp.additionalNotes)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
            )
        )
    }

    private var sectionsCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(DetailSection.allCases.enumerated()), id: \.element) { index, section in
                DisclosureGroup(
                    isExpanded: Binding(
                        get: { expandedSections.contains(section) },
                        set: { isOn in
                            if isOn { expandedSections.insert(section) }
                            else { expandedSections.remove(section) }
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
                .tint(Color.brandOrange)
                .padding(.horizontal, 16)

                if index < DetailSection.allCases.count - 1 {
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
            store.add(stamp)
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
        .tint(Color.brandOrange)
        .controlSize(.large)
        .disabled(didAdd)
    }

    // MARK: Helpers

    private var valueDisplay: String {
        StampStore.currencyFormatter.string(from: NSNumber(value: stamp.estimatedValue))
            ?? "$\(Int(stamp.estimatedValue))"
    }

    private func labelledRow(icon: String, title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: icon)
                .frame(width: 22)
                .foregroundStyle(Color.brandOrange)
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

    private func content(for section: DetailSection) -> String {
        switch section {
        case .description: return stamp.description
        case .physical:    return stamp.physicalAnalysis
        case .historical:  return stamp.historicalContext
        case .value:       return stamp.valueAnalysis
        case .collector:   return stamp.collectorInfo
        }
    }
}

private struct ConfidencePill: View {
    let confidence: Double

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkles")
            Text("AI Confidence: \(Int(confidence * 100))%")
        }
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule().fill(Color.black.opacity(0.65))
        )
        .foregroundStyle(.white)
    }
}

#Preview {
    NavigationStack {
        StampDetailView(stamp: .samplePennyBlack, showsAddButton: true)
            .environmentObject(StampStore())
    }
}
