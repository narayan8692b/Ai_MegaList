import SwiftUI

@main
struct StampIdentifierApp: App {
    @StateObject private var store = StampStore()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(store)
                .preferredColorScheme(.light)
        }
    }
}
