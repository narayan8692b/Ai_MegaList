import SwiftUI

struct CollectionView: View {
    @EnvironmentObject private var stampStore: StampStore
    @EnvironmentObject private var antiqueStore: AntiqueStore
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
                (mode == .stamp ? Color.brandCream : Color.antiqueCream)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        modeSwitcher
                        summaryCard
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
            .navigationTitle(mode == .stamp ? "Collection" : "Identification History")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: Stamp.self) { stamp in
                StampDetailView(stamp: stamp)
            }
            .navigationDestination(for: Antique.self) { antique in
                AntiqueDetailView(antique: antique)
            }
        }
    }

    // MARK: Subviews

    private var modeSwitcher: some View {
        Picker("Mode", selection: $storedMode) {
            ForEach(CollectibleMode.allCases) { m in
                Text(m.rawValue).tag(m.rawValue)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }

    private var summaryCard: some View {
        HStack(spacing: 12) {
            summaryTile(
                title: "Total Items",
                value: "\(currentCount)",
                icon: "square.stack.fill")
            summaryTile(
                title: "Total Value",
                value: currentFormattedValue,
                icon: "dollarsign.circle.fill")
        }
        .padding(.horizontal)
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
                        colors: [mode.accentColor,
                                 mode.accentColor.opacity(0.75)],
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
                        Button(role: .destructive) {
                            stampStore.remove(stamp)
                        } label: {
                            Label("Remove from Collection", systemImage: "trash")
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
                        Button(role: .destructive) {
                            antiqueStore.remove(antique)
                        } label: {
                            Label("Remove from Collection", systemImage: "trash")
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
            Text(searchText.isEmpty
                 ? (mode == .stamp
                    ? "Your stamp collection is empty."
                    : "Your antique history is empty.")
                 : "No items match “\(searchText)”.")
                .font(.headline)
                .foregroundStyle(Color.brandInk)
            if searchText.isEmpty {
                Text(mode == .stamp
                     ? "Scan a stamp to add your first entry."
                     : "Scan an antique to start your history.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 50)
    }

    // MARK: Data helpers

    private var isEmpty: Bool {
        switch mode {
        case .stamp:   return filteredStamps.isEmpty
        case .antique: return filteredAntiques.isEmpty
        }
    }

    private var currentCount: Int {
        switch mode {
        case .stamp:   return stampStore.totalCount
        case .antique: return antiqueStore.totalCount
        }
    }

    private var currentFormattedValue: String {
        switch mode {
        case .stamp:   return stampStore.formattedTotalValue
        case .antique: return antiqueStore.formattedTotalValue
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
}

#Preview {
    CollectionView()
        .environmentObject(StampStore())
        .environmentObject(AntiqueStore())
}
