import SwiftUI

@main
struct NoteHiveAIApp: App {
    @StateObject private var store = RecordingsStore()
    @StateObject private var settings = AppSettings()

    var body: some Scene {
        WindowGroup {
            RecordingsListView()
                .environmentObject(store)
                .environmentObject(settings)
                .preferredColorScheme(.dark)
        }
    }
}
