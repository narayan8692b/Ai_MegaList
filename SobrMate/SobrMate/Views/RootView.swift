import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            TrackersListView()
                .tabItem { Label("Trackers", systemImage: "flame.fill") }

            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.bar.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(AppColor.accent)
    }
}
