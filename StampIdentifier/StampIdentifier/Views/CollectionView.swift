import SwiftUI

struct CollectionView: View {
    @EnvironmentObject private var stampStore:   StampStore
    @EnvironmentObject private var antiqueStore: AntiqueStore
    @EnvironmentObject private var jewelryStore: JewelryStore
    @EnvironmentObject private var coinStore:    CoinStore

    @AppStorage("selectedMode") private var storedMode: String = CollectibleMode.stamp.rawValue
    @State private var searchText = ""

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    private var mode: CollectibleMode {
        CollectibleMode(rawValue: storedMode) ?? .stamp
    }

    var body: some View {
        NavigationStack {
            ZStack {
                mode.backgroundColor.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        ModeChipPicker(selection: $storedMode)
                        totalsCard
                        if isEmpty {
                            emptyState
                        } else {
                            grid
                        }
                    }
                    .padding(.vertical, 16)
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(mode == .coin ? .dark : .light, for: .navigationBar)
            .navigationDestination(for: Stamp.self)   { stamp in   StampDetailView(stamp: stamp) }
            .navigationDestination(for: Antique.self) { antique in AntiqueDetailView(antique: antique) }
            .navigationDestination(for: Jewelry.self) { piece in   JewelryDetailView(piece: piece) }
            .navigationDestination(for: Coin.self)    { coin in    CoinDetailView(coin: coin) }
        }
    }

    // MARK: Subviews

    private var title: String {
        switch mode {
        case .stamp:   return "Collection"
        case .antique: return "Identification History"
        case .jewelry: return "Jewelry"
        case .coin:    return "Coins"
        }
    }

    private var totalsCard: some View {
        Group {
            if mode == .jewelry {
                bigValuePill
            } else {
                dualTiles
            }
        }
        .padding(.horizontal)
    }

    private var bigValuePill: some View {
        VStack(spacing: 6) {
            Text(currentFormattedValue)
                .font(.system(size: 48, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.brandInk)
            Text("\(currentCount) pieces tracked")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .padding(.horizontal, 16)
        .background(
            Capsule(style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
        )
        .overlay(
            Capsule(style: .continuous)
                .strokeBorder(Color.jewelryGold.opacity(0.35), lineWidth: 2)
        )
    }

    private var dualTiles: some View {
        HStack(spacing: 12) {
            summaryTile(title: "Total Items",
                        value: "\(currentCount)",
                        icon: "square.stack.fill")
            summaryTile(title: "Total Value",
                        value: currentFormattedValue,
                        icon: "dollarsign.circle.fill")
        }
    }

    private func summaryTile(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.white.opacity(0.9))
            Text(value)
                .font(.system(.title2, design: .rounded, weight: .heavy))
                .foregroundStyle(.white)
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [mode.accentColor, mode.accentColor.opacity(0.75)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }

    @ViewBuilder
    private var grid: some View {
        switch mode {
        case .stamp:
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(filteredStamps) { stamp in
                    NavigationLink(value: stamp) {
                        StampCardView(stamp: stamp)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) { stampStore.remove(stamp) } label: {
                            Label("Remove", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal)
        case .antique:
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(filteredAntiques) { antique in
                    NavigationLink(value: antique) {
                        AntiqueCardView(antique: antique)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) { antiqueStore.remove(antique) } label: {
                            Label("Remove", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal)
        case .jewelry:
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(filteredJewelry) { piece in
                    NavigationLink(value: piece) {
                        JewelryCardView(piece: piece)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) { jewelryStore.remove(piece) } label: {
                            Label("Remove", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal)
        case .coin:
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(filteredCoins) { coin in
                    NavigationLink(value: coin) {
                        CoinCardView(coin: coin)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) { coinStore.remove(coin) } label: {
                            Label("Remove", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "tray")
                .font(.system(size: 52, weight: .light))
                .foregroundStyle(mode.accentColor)
            Text(searchText.isEmpty ? emptyTitle : "No items match “\(searchText)”.")
                .font(.headline)
                .foregroundStyle(mode == .coin ? .white : Color.brandInk)
            if searchText.isEmpty {
                Text("Scan a \(mode.singular.lowercased()) to add your first entry.")
                    .font(.subheadline)
                    .foregroundStyle(mode == .coin ? Color.white.opacity(0.65) : .secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 50)
    }

    private var emptyTitle: String {
        switch mode {
        case .stamp:   return "Your stamp collection is empty."
        case .antique: return "Your antique history is empty."
        case .jewelry: return "Your jewelry collection is empty."
        case .coin:    return "Your coin history is empty."
        }
    }

    // MARK: Data helpers

    private var isEmpty: Bool {
        switch mode {
        case .stamp:   return filteredStamps.isEmpty
        case .antique: return filteredAntiques.isEmpty
        case .jewelry: return filteredJewelry.isEmpty
        case .coin:    return filteredCoins.isEmpty
        }
    }

    private var currentCount: Int {
        switch mode {
        case .stamp:   return stampStore.totalCount
        case .antique: return antiqueStore.totalCount
        case .jewelry: return jewelryStore.totalCount
        case .coin:    return coinStore.totalCount
        }
    }

    private var currentFormattedValue: String {
        switch mode {
        case .stamp:   return stampStore.formattedTotalValue
        case .antique: return antiqueStore.formattedTotalValue
        case .jewelry: return jewelryStore.formattedTotalValue
        case .coin:    return coinStore.formattedTotalValue
        }
    }

    private var filteredStamps: [Stamp] {
        let base = stampStore.stamps
        guard !searchText.isEmpty else { return base }
        let q = searchText.lowercased()
        return base.filter {
            $0.name.lowercased().contains(q) ||
            $0.country.lowercased().contains(q) ||
            $0.catalogNumbersDisplay.lowercased().contains(q)
        }
    }

    private var filteredAntiques: [Antique] {
        let base = antiqueStore.antiques
        guard !searchText.isEmpty else { return base }
        let q = searchText.lowercased()
        return base.filter {
            $0.name.lowercased().contains(q) ||
            $0.shortTitle.lowercased().contains(q) ||
            $0.category.rawValue.lowercased().contains(q) ||
            $0.style.lowercased().contains(q)
        }
    }

    private var filteredJewelry: [Jewelry] {
        let base = jewelryStore.pieces
        guard !searchText.isEmpty else { return base }
        let q = searchText.lowercased()
        return base.filter {
            $0.name.lowercased().contains(q) ||
            $0.shortTitle.lowercased().contains(q) ||
            $0.type.rawValue.lowercased().contains(q)
        }
    }

    private var filteredCoins: [Coin] {
        let base = coinStore.coins
        guard !searchText.isEmpty else { return base }
        let q = searchText.lowercased()
        return base.filter {
            $0.name.lowercased().contains(q) ||
            $0.shortTitle.lowercased().contains(q) ||
            $0.country.lowercased().contains(q) ||
            $0.denomination.lowercased().contains(q)
        }
    }
}

#Preview {
    CollectionView()
        .environmentObject(StampStore())
        .environmentObject(AntiqueStore())
        .environmentObject(JewelryStore())
        .environmentObject(CoinStore())
}
