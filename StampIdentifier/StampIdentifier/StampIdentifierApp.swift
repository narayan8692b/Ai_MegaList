import SwiftUI

@main
struct StampIdentifierApp: App {
    @StateObject private var stampStore = StampStore()
    @StateObject private var antiqueStore = AntiqueStore()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(stampStore)
                .environmentObject(antiqueStore)
                .preferredColorScheme(.light)
        }
    }
}
