import SwiftUI

struct ContentView: View {
    @EnvironmentObject var settingsStore: SettingsStore
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            HomeView()
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gear")
                                .foregroundColor(.white)
                        }
                    }
                }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(settingsStore)
        }
        .tint(.orange)
    }
}
