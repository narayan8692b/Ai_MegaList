import Foundation
import Combine

@MainActor
final class CoinStore: ObservableObject {
    @Published private(set) var coins: [Coin] = []

    private let storageKey = "coin.collection.v1"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard, seedIfEmpty: Bool = true) {
        self.defaults = defaults
        load()
        if coins.isEmpty && seedIfEmpty {
            coins = Coin.seedCollection
            save()
        }
    }

    var totalCount: Int { coins.count }

    var totalValue: Double {
        coins.reduce(0) { $0 + $1.estimatedValue }
    }

    var formattedTotalValue: String {
        CurrencyFormatter.usd.string(from: NSNumber(value: totalValue)) ?? "$0"
    }

    func add(_ coin: Coin) {
        coins.insert(coin, at: 0)
        save()
    }

    func remove(_ coin: Coin) {
        coins.removeAll { $0.id == coin.id }
        save()
    }

    private func load() {
        guard let data = defaults.data(forKey: storageKey) else { return }
        do { coins = try JSONDecoder().decode([Coin].self, from: data) }
        catch { coins = [] }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(coins)
            defaults.set(data, forKey: storageKey)
        } catch { }
    }
}
