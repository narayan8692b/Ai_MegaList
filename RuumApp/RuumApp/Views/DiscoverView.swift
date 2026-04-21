import SwiftUI

struct DiscoverView: View {
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(DesignStyle.all) { style in
                        NavigationLink {
                            InteriorDesignView(mode: .interior, preselectedStyle: style)
                        } label: {
                            StyleCard(style: style, isSelected: false, action: {})
                                .allowsHitTesting(false)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(Layout.padding)
            }
            .background(Color.ruumBackground.ignoresSafeArea())
            .navigationTitle("Discover Styles")
        }
    }
}
