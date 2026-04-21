import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var exchangeService: ExchangeRateService
    @AppStorage("decimalPlaces") private var decimalPlaces = 2
    @AppStorage("scannerSource")  private var scannerSource = "EUR"
    @AppStorage("scannerTarget")  private var scannerTarget = "USD"

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        NavigationView {
            List {

                // MARK: Exchange Rates
                Section("Exchange Rates") {
                    HStack {
                        Label("Source", systemImage: "globe")
                        Spacer()
                        Text("open.er-api.com")
                            .foregroundColor(.secondary)
                            .font(.footnote)
                    }
                    HStack {
                        Label("Status", systemImage: exchangeService.isOnline ? "checkmark.circle.fill" : "wifi.slash")
                            .foregroundColor(exchangeService.isOnline ? .green : .orange)
                        Spacer()
                        Text(exchangeService.isOnline ? "Live" : "Offline (built-in rates)")
                            .foregroundColor(.secondary)
                            .font(.footnote)
                    }
                    Button {
                        Task { await exchangeService.refresh() }
                    } label: {
                        Label("Refresh Rates Now", systemImage: "arrow.clockwise")
                    }
                }

                // MARK: Display
                Section("Display") {
                    Picker(selection: $decimalPlaces) {
                        Text("2 places").tag(2)
                        Text("4 places").tag(4)
                        Text("6 places").tag(6)
                    } label: {
                        Label("Decimal Places", systemImage: "number")
                    }
                    .pickerStyle(.menu)
                }

                // MARK: About
                Section("About") {
                    HStack {
                        Label("App Version", systemImage: "info.circle")
                        Spacer()
                        Text(appVersion).foregroundColor(.secondary)
                    }
                    HStack {
                        Label("OCR Engine", systemImage: "camera.viewfinder")
                        Spacer()
                        Text("Apple Vision (offline)").foregroundColor(.secondary).font(.footnote)
                    }
                    HStack {
                        Label("Currencies", systemImage: "banknote")
                        Spacer()
                        Text("\(Currency.all.count) supported").foregroundColor(.secondary).font(.footnote)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
        }
    }
}
