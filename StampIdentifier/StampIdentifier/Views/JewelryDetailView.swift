import SwiftUI

struct JewelryDetailView: View {
    @EnvironmentObject private var store: JewelryStore
    @Environment(\.dismiss) private var dismiss

    let piece: Jewelry
    var showsAddButton: Bool = false

    @State private var didAdd = false
    @State private var showChat = false
    @State private var showEBay = false

    var body: some View {
        ZStack {
            Color.jewelryCream.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    heroImage
                    titleAndValueCard
                    summaryCard
                    materialsCard
                    hallmarksCard
                    valueJustificationCard
                    advisorButtons
                }
                .padding(.vertical, 16)
                .padding(.horizontal)
            }
        }
        .navigationTitle("Jewelry Details")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            if showsAddButton { addButton.padding(.horizontal).padding(.bottom, 12) }
        }
        .sheet(isPresented: $showChat) {
            JewelryChatView(piece: piece)
        }
        .sheet(isPresented: $showEBay) {
            EBayCheckerView(piece: piece)
        }
    }

    // MARK: Subviews

    private var heroImage: some View {
        Group {
            if let data = piece.imageData, let image = UIImage(data: data) {
                Image(uiImage: image).resizable().scaledToFit()
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.jewelryGold.opacity(0.08))
                    .frame(height: 220)
                    .overlay {
                        Image(systemName: "sparkles")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.jewelryGold)
                    }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var titleAndValueCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(piece.name)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(Color.brandInk)
            Text("\(piece.type.rawValue) · \(piece.eraLabel)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("ESTIMATED VALUE")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.top, 8)

            Text(piece.estimatedValueDisplay)
                .font(.system(size: 36, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.brandInk)

            Text(piece.valueRangeDisplay)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Summary", systemImage: "text.alignleft")
                .font(.headline)
                .foregroundStyle(Color.brandInk)
            Text(piece.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }

    private var materialsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Materials")
                .font(.headline)
                .foregroundStyle(Color.brandInk)

            ForEach(piece.metals, id: \.self) { metal in
                materialRow(
                    title: metal.material,
                    subtitle: metal.displayLine,
                    icon: "circle.grid.cross"
                )
            }

            ForEach(piece.gemstones, id: \.self) { gem in
                materialRow(
                    title: gem.species,
                    subtitle: gem.displayLine,
                    icon: "diamond"
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }

    private func materialRow(title: String, subtitle: String, icon: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(Color.jewelryGold)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.brandInk)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.jewelryGold.opacity(0.06))
        )
    }

    @ViewBuilder
    private var hallmarksCard: some View {
        if piece.hallmarks.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 10) {
                Text("Hallmarks")
                    .font(.headline)
                    .foregroundStyle(Color.brandInk)
                HStack(spacing: 8) {
                    ForEach(piece.hallmarks, id: \.self) { mark in
                        Text(mark)
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule().fill(Color.jewelryGold.opacity(0.18))
                            )
                            .foregroundStyle(Color.jewelryGold)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
            )
        }
    }

    private var valueJustificationCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Value justification", systemImage: "scalemass")
                .font(.headline)
                .foregroundStyle(Color.brandInk)
            Text(piece.valueJustification)
                .font(.footnote.monospaced())
                .foregroundStyle(Color.brandInk)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.jewelryGold.opacity(0.06))
                )

            Text("Comparable sales")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.brandInk)
                .padding(.top, 4)
            Text(piece.marketNotes)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }

    private var advisorButtons: some View {
        HStack(spacing: 12) {
            Button {
                showChat = true
            } label: {
                Label("Ask AI", systemImage: "sparkles")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
            .tint(Color.jewelryGold)

            Button {
                showEBay = true
            } label: {
                Label("Check eBay", systemImage: "cart")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
            .tint(Color.jewelryGold)
        }
    }

    private var addButton: some View {
        Button {
            store.add(piece)
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
        .tint(Color.jewelryGold)
        .controlSize(.large)
        .disabled(didAdd)
    }
}

#Preview {
    NavigationStack {
        JewelryDetailView(piece: .sampleBaroquePearl, showsAddButton: true)
            .environmentObject(JewelryStore())
    }
}
