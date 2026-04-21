import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var storage: DesignStorage

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            Group {
                if storage.designs.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(storage.designs) { design in
                                NavigationLink {
                                    DesignResultView(design: design)
                                } label: {
                                    HistoryCard(design: design)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(Layout.padding)
                    }
                }
            }
            .background(Color.ruumBackground.ignoresSafeArea())
            .navigationTitle("History")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 50))
                .foregroundColor(.ruumTeal)
            Text("No designs yet")
                .font(.headline)
            Text("Your generated rooms will appear here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct HistoryCard: View {
    @EnvironmentObject private var storage: DesignStorage
    let design: Design

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Group {
                if let img = storage.image(named: design.generatedImageFilename) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                } else {
                    Color.ruumCard
                }
            }
            .frame(height: 160)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(design.style.name)
                    .font(.subheadline.weight(.semibold))
                HStack(spacing: 6) {
                    Image(systemName: design.room.sfSymbol)
                        .font(.caption2)
                    Text(design.room.name)
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .background(Color.ruumCard, in: RoundedRectangle(cornerRadius: Layout.tileRadius, style: .continuous))
    }
}
