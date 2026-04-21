import SwiftUI

struct CollectionView: View {
    @EnvironmentObject private var store: StampStore
    @State private var searchText = ""

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.brandCream.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        summaryCard
                        if filteredStamps.isEmpty {
                            emptyState
                        } else {
                            LazyVGrid(columns: columns, spacing: 14) {
                                ForEach(filteredStamps) { stamp in
                                    NavigationLink(value: stamp) {
                                        StampCardView(stamp: stamp)
                                    }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            store.remove(stamp)
                                        } label: {
                                            Label("Remove from Collection",
                                                  systemImage: "trash")
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 16)
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .navigationTitle("Collection")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: Stamp.self) { stamp in
                StampDetailView(stamp: stamp)
            }
        }
    }

    // MARK: Subviews

    private var summaryCard: some View {
        HStack(spacing: 12) {
            summaryTile(
                title: "Total Stamps",
                value: "\(store.totalCount)",
                icon: "square.stack.fill")
            summaryTile(
                title: "Total Value",
                value: store.formattedTotalValue,
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
                        colors: [Color.brandOrange, Color.brandOrange.opacity(0.75)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "tray")
                .font(.system(size: 52, weight: .light))
                .foregroundStyle(Color.brandOrange)
            Text(searchText.isEmpty ? "Your collection is empty." : "No stamps match “\(searchText)”.")
                .font(.headline)
                .foregroundStyle(Color.brandInk)
            if searchText.isEmpty {
                Text("Scan a stamp to add your first entry.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 50)
    }

    private var filteredStamps: [Stamp] {
        let base = store.stamps
        guard !searchText.isEmpty else { return base }
        let query = searchText.lowercased()
        return base.filter {
            $0.name.lowercased().contains(query) ||
            $0.country.lowercased().contains(query) ||
            $0.catalogNumbersDisplay.lowercased().contains(query)
        }
    }
}

#Preview {
    CollectionView().environmentObject(StampStore())
}
