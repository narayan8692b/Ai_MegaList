import Foundation
import Combine

@MainActor
final class StampStore: ObservableObject {
    @Published private(set) var stamps: [Stamp] = []

    private let storageKey = "stamp.collection.v1"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard, seedIfEmpty: Bool = true) {
        self.defaults = defaults
        load()
        if stamps.isEmpty && seedIfEmpty {
            stamps = Stamp.seedCollection
            save()
        }
    }

    var totalCount: Int { stamps.count }

    var totalValue: Double {
        stamps.reduce(0) { $0 + $1.estimatedValue }
    }

    var formattedTotalValue: String {
        Self.currencyFormatter.string(from: NSNumber(value: totalValue)) ?? "$0"
    }

    func add(_ stamp: Stamp) {
        stamps.insert(stamp, at: 0)
        save()
    }

    func remove(_ stamp: Stamp) {
        stamps.removeAll { $0.id == stamp.id }
        save()
    }

    func remove(at offsets: IndexSet) {
        stamps.remove(atOffsets: offsets)
        save()
    }

    func update(_ stamp: Stamp) {
        guard let idx = stamps.firstIndex(where: { $0.id == stamp.id }) else { return }
        stamps[idx] = stamp
        save()
    }

    private func load() {
        guard let data = defaults.data(forKey: storageKey) else { return }
        do {
            stamps = try JSONDecoder().decode([Stamp].self, from: data)
        } catch {
            stamps = []
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(stamps)
            defaults.set(data, forKey: storageKey)
        } catch {
            // Intentional: persistence failure should not crash the app.
        }
    }

    static let currencyFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        f.maximumFractionDigits = 0
        return f
    }()
}
