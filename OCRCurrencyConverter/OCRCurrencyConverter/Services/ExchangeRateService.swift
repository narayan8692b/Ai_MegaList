import Foundation
import Combine

final class ExchangeRateService: ObservableObject {

    @Published var rates: [String: Double] = Self.fallbackRates
    @Published var isOnline = false

    // Rates relative to EUR — used when network unavailable
    static let fallbackRates: [String: Double] = [
        "EUR": 1.0,    "USD": 1.08,  "GBP": 0.86,  "JPY": 162.5,
        "CAD": 1.47,   "AUD": 1.64,  "CHF": 0.97,  "CNY": 7.82,
        "INR": 90.2,   "MXN": 18.5,  "BRL": 5.4,   "KRW": 1430.0,
        "SGD": 1.45,   "HKD": 8.45,  "NOK": 11.4,  "SEK": 11.2,
        "DKK": 7.46,   "NZD": 1.77,  "ZAR": 20.1,  "TRY": 34.8,
        "PLN": 4.28,   "CZK": 25.2,  "HUF": 398.0, "ILS": 4.02,
        "AED": 3.97,   "SAR": 4.05,  "THB": 38.5,  "MYR": 5.07,
        "IDR": 17250.0,"RUB": 98.5,
    ]

    private let cacheRatesKey = "cachedExchangeRates"
    private let cacheTimeKey  = "cachedExchangeRatesTime"
    private let cacheTTL: TimeInterval = 3600

    init() {
        loadCache()
        Task { await fetchRates() }
    }

    func convert(amount: Double, from: String, to: String) -> Double? {
        guard let fromRate = rates[from], let toRate = rates[to], fromRate > 0 else { return nil }
        return (amount / fromRate) * toRate
    }

    // MARK: - Private

    @MainActor
    private func fetchRates() async {
        // open.er-api.com — free, no key required (1 500 req/month)
        guard let url = URL(string: "https://open.er-api.com/v6/latest/EUR") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(ExchangeRateResponse.self, from: data)
            guard response.result == "success" else { return }
            rates = response.rates
            isOnline = true
            persistCache(response.rates)
        } catch {
            // Network unavailable — fallback rates already applied
        }
    }

    private func loadCache() {
        guard
            let cached = UserDefaults.standard.dictionary(forKey: cacheRatesKey) as? [String: Double],
            let ts = UserDefaults.standard.object(forKey: cacheTimeKey) as? Date,
            Date().timeIntervalSince(ts) < cacheTTL
        else { return }
        rates = cached
    }

    private func persistCache(_ newRates: [String: Double]) {
        UserDefaults.standard.set(newRates, forKey: cacheRatesKey)
        UserDefaults.standard.set(Date(), forKey: cacheTimeKey)
    }
}
