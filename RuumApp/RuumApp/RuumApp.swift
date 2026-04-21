import SwiftUI

@main
struct RuumAppMain: App {
    @StateObject private var storage = DesignStorage()
    @StateObject private var designService = AIDesignService()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(storage)
                .environmentObject(designService)
                .preferredColorScheme(.light)
                .tint(Color.ruumTeal)
        }
    }
}
