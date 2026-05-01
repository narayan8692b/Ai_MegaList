import SwiftUI

struct RootView: View {
    @State private var selectedTab: Tab = .home

    enum Tab: Hashable {
        case home
        case library
        case settings
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Scan", systemImage: "cube.transparent.fill")
                }
                .tag(Tab.home)

            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "square.stack.3d.up.fill")
                }
                .tag(Tab.library)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(Tab.settings)
        }
        .tint(.blue)
    }
}

#Preview {
    RootView()
        .environmentObject(ScanStore())
}
