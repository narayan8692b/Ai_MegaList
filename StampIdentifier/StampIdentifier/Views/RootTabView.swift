import SwiftUI

struct RootTabView: View {
    @State private var selection: Tab = .scan
    @AppStorage("selectedMode") private var storedMode: String = CollectibleMode.stamp.rawValue

    enum Tab: Hashable {
        case scan, collection, learn
    }

    private var mode: CollectibleMode {
        CollectibleMode(rawValue: storedMode) ?? .stamp
    }

    var body: some View {
        TabView(selection: $selection) {
            ScanView()
                .tabItem { Label("Scan", systemImage: "viewfinder.circle.fill") }
                .tag(Tab.scan)

            CollectionView()
                .tabItem { Label("Collection", systemImage: "square.stack.3d.up.fill") }
                .tag(Tab.collection)

            LearnView()
                .tabItem { Label("Learn", systemImage: "book.fill") }
                .tag(Tab.learn)
        }
        .tint(mode.accentColor)
    }
}

#Preview {
    RootTabView()
        .environmentObject(StampStore())
        .environmentObject(AntiqueStore())
        .environmentObject(JewelryStore())
        .environmentObject(CoinStore())
}
