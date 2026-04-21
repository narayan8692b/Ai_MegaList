import SwiftUI

@main
struct StampIdentifierApp: App {
    @StateObject private var stampStore   = StampStore()
    @StateObject private var antiqueStore = AntiqueStore()
    @StateObject private var jewelryStore = JewelryStore()
    @StateObject private var coinStore    = CoinStore()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(stampStore)
                .environmentObject(antiqueStore)
                .environmentObject(jewelryStore)
                .environmentObject(coinStore)
                .preferredColorScheme(.light)
        }
    }
}
