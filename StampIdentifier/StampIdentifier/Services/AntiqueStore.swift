import Foundation
import Combine

@MainActor
final class AntiqueStore: ObservableObject {
    @Published private(set) var antiques: [Antique] = []

    private let storageKey = "antique.collection.v1"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard, seedIfEmpty: Bool = true) {
        self.defaults = defaults
        load()
        if antiques.isEmpty && seedIfEmpty {
            antiques = Antique.seedCollection
            save()
        }
    }

    var totalCount: Int { antiques.count }

    var totalValue: Double {
        antiques.reduce(0) { $0 + $1.estimatedValue }
    }

    var formattedTotalValue: String {
        CurrencyFormatter.usd.string(from: NSNumber(value: totalValue)) ?? "$0"
    }

    func add(_ antique: Antique) {
        antiques.insert(antique, at: 0)
        save()
    }

    func remove(_ antique: Antique) {
        antiques.removeAll { $0.id == antique.id }
        save()
    }

    func update(_ antique: Antique) {
        guard let idx = antiques.firstIndex(where: { $0.id == antique.id }) else { return }
        antiques[idx] = antique
        save()
    }

    private func load() {
        guard let data = defaults.data(forKey: storageKey) else { return }
        do {
            antiques = try JSONDecoder().decode([Antique].self, from: data)
        } catch {
            antiques = []
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(antiques)
            defaults.set(data, forKey: storageKey)
        } catch {
            // Intentional: persistence failure should not crash the app.
        }
    }
}
