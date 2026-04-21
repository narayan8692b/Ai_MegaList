import SwiftUI

struct HomeView: View {
    @State private var selectedMode: DesignMode?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header

                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                              spacing: 12) {
                        ForEach(DesignMode.allCases) { mode in
                            ModeTile(mode: mode) {
                                selectedMode = mode
                            }
                        }
                    }

                    SectionHeader(title: "Discover")
                    discoverGrid
                }
                .padding(Layout.padding)
            }
            .background(Color.ruumBackground.ignoresSafeArea())
            .navigationTitle("Interior Design AI")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(item: $selectedMode) { mode in
                InteriorDesignView(mode: mode)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Redesign any space")
                .font(.title2.weight(.bold))
            Text("Pick a mode to begin. Ruum turns a photo into a styled render in seconds.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var discoverGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                  spacing: 12) {
            ForEach(DesignStyle.all.prefix(6)) { style in
                DiscoverCard(style: style)
            }
        }
    }
}

private struct DiscoverCard: View {
    let style: DesignStyle
    @State private var isPushed = false

    var body: some View {
        NavigationLink {
            InteriorDesignView(mode: .interior, preselectedStyle: style)
        } label: {
            ZStack(alignment: .bottomLeading) {
                LinearGradient(colors: style.colors,
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
                    .frame(height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: Layout.tileRadius, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(style.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(style.tagline)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(12)
            }
        }
        .buttonStyle(.plain)
    }
}
