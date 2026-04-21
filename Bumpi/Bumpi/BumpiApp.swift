import SwiftUI

@main
struct BumpiApp: App {
    @StateObject private var profileStore = BabyProfileStore()
    @StateObject private var recordingStore = RecordingStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(profileStore)
                .environmentObject(recordingStore)
                .preferredColorScheme(.light)
        }
    }
}
