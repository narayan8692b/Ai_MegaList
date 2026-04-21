import SwiftUI

@main
struct RoastBotApp: App {
    @StateObject private var settingsStore = SettingsStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settingsStore)
                .preferredColorScheme(.dark)
        }
    }
}
