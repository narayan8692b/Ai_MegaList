import SwiftUI

@main
struct SobrMateApp: App {
    @StateObject private var store = HabitStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
        }
    }
}
