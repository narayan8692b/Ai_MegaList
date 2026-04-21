import SwiftUI

struct RootTabView: View {
    @State private var selection: Tab = .scan

    enum Tab: Hashable {
        case scan, collection, learn
    }

    var body: some View {
        TabView(selection: $selection) {
            ScanView()
                .tabItem {
                    Label("Scan", systemImage: "viewfinder.circle.fill")
                }
                .tag(Tab.scan)

            CollectionView()
                .tabItem {
                    Label("Collection", systemImage: "square.stack.3d.up.fill")
                }
                .tag(Tab.collection)

            LearnView()
                .tabItem {
                    Label("Learn", systemImage: "book.fill")
                }
                .tag(Tab.learn)
        }
        .tint(Color.brandOrange)
    }
}

#Preview {
    RootTabView()
        .environmentObject(StampStore())
}
