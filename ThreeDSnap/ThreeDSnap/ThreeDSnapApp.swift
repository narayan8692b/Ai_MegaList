import SwiftUI

@main
struct ThreeDSnapApp: App {
    @StateObject private var scanStore = ScanStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(scanStore)
                .preferredColorScheme(.dark)
        }
    }
}
