import SwiftUI

struct ContentView: View {
    @StateObject private var exchangeService = ExchangeRateService()

    var body: some View {
        TabView {
            ScannerView()
                .tabItem { Label("Scanner", systemImage: "viewfinder") }

            ConverterView()
                .tabItem { Label("Converter", systemImage: "arrow.left.arrow.right.circle") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "slider.horizontal.3") }
        }
        .environmentObject(exchangeService)
    }
}

#Preview {
    ContentView()
}
