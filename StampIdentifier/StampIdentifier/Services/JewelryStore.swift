import Foundation
import Combine

@MainActor
final class JewelryStore: ObservableObject {
    @Published private(set) var pieces: [Jewelry] = []

    private let storageKey = "jewelry.collection.v1"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard, seedIfEmpty: Bool = true) {
        self.defaults = defaults
        load()
        if pieces.isEmpty && seedIfEmpty {
            pieces = Jewelry.seedCollection
            save()
        }
    }

    var totalCount: Int { pieces.count }

    var totalValue: Double {
        pieces.reduce(0) { $0 + $1.estimatedValue }
    }

    var formattedTotalValue: String {
        CurrencyFormatter.usd.string(from: NSNumber(value: totalValue)) ?? "$0"
    }

    func add(_ piece: Jewelry) {
        pieces.insert(piece, at: 0)
        save()
    }

    func remove(_ piece: Jewelry) {
        pieces.removeAll { $0.id == piece.id }
        save()
    }

    private func load() {
        guard let data = defaults.data(forKey: storageKey) else { return }
        do { pieces = try JSONDecoder().decode([Jewelry].self, from: data) }
        catch { pieces = [] }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(pieces)
            defaults.set(data, forKey: storageKey)
        } catch { }
    }
}
