import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Design", systemImage: "sparkles") }

            DiscoverView()
                .tabItem { Label("Discover", systemImage: "square.grid.2x2") }

            HistoryView()
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}
