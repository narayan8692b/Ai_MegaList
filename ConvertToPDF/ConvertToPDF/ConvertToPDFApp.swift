import SwiftUI

@main
struct ConvertToPDFApp: App {
    @StateObject private var store = DocumentStore()

    var body: some Scene {
        WindowGroup {
            DocumentListView()
                .environmentObject(store)
                .tint(Theme.accent)
        }
    }
}
