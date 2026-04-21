import Foundation
import Combine

final class ConverterViewModel: ObservableObject {

    @Published var currencies: [Currency]
    @Published var baseCurrencyId: String
    @Published var baseAmountText: String = "1"

    var baseAmount: Double { Double(baseAmountText.replacingOccurrences(of: ",", with: ".")) ?? 1 }

    private let currenciesKey = "converterCurrencies"
    private let baseKey       = "converterBase"

    init() {
        let saved = UserDefaults.standard.stringArray(forKey: "converterCurrencies") ?? ["CAD", "EUR", "USD"]
        currencies = saved.map { Currency.find(by: $0) }
        baseCurrencyId = UserDefaults.standard.string(forKey: "converterBase") ?? saved.first ?? "USD"
    }

    func setBase(_ currency: Currency) {
        baseCurrencyId = currency.id
        UserDefaults.standard.set(baseCurrencyId, forKey: baseKey)
    }

    func addCurrency(_ currency: Currency) {
        guard !currencies.contains(where: { $0.id == currency.id }) else { return }
        currencies.append(currency)
        persist()
    }

    func removeCurrencies(at offsets: IndexSet) {
        let removedIds = offsets.map { currencies[$0].id }
        currencies.remove(atOffsets: offsets)
        if removedIds.contains(baseCurrencyId) {
            baseCurrencyId = currencies.first?.id ?? "USD"
            UserDefaults.standard.set(baseCurrencyId, forKey: baseKey)
        }
        persist()
    }

    func moveCurrencies(from source: IndexSet, to destination: Int) {
        currencies.move(fromOffsets: source, toOffset: destination)
        persist()
    }

    private func persist() {
        UserDefaults.standard.set(currencies.map(\.id), forKey: currenciesKey)
    }
}
