import Foundation
import Combine

@MainActor
final class ScanStore: ObservableObject {
    @Published private(set) var scans: [Scan] = []

    private let fileURL: URL
    private let queue = DispatchQueue(label: "ScanStore.io", qos: .utility)

    init(fileName: String = "scans.json") {
        let directory = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        self.fileURL = directory.appendingPathComponent(fileName)
        load()
    }

    func add(_ scan: Scan) {
        scans.insert(scan, at: 0)
        persist()
    }

    func update(_ scan: Scan) {
        guard let idx = scans.firstIndex(where: { $0.id == scan.id }) else { return }
        scans[idx] = scan
        persist()
    }

    func delete(id: UUID) {
        scans.removeAll { $0.id == id }
        persist()
    }

    func rename(id: UUID, to newName: String) {
        guard let idx = scans.firstIndex(where: { $0.id == id }) else { return }
        scans[idx].name = newName
        persist()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let decoded = try? decoder.decode([Scan].self, from: data) {
            self.scans = decoded
        }
    }

    private func persist() {
        let snapshot = scans
        let url = fileURL
        queue.async {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            do {
                let data = try encoder.encode(snapshot)
                try data.write(to: url, options: .atomic)
            } catch {
                #if DEBUG
                print("ScanStore persist failed:", error)
                #endif
            }
        }
    }
}

extension ScanStore {
    static var preview: ScanStore {
        let store = ScanStore(fileName: "preview-scans.json")
        if store.scans.isEmpty {
            store.add(Scan(
                name: "Jun 4, File 7",
                rooms: [
                    Room(name: "Living",
                         origin: CGPoint(x: 0, y: 0),
                         size: CGSize(width: 5.7, height: 4.0)),
                    Room(name: "Bedroom",
                         origin: CGPoint(x: 0, y: 4.0),
                         size: CGSize(width: 3.5, height: 3.2)),
                    Room(name: "Bath",
                         origin: CGPoint(x: 3.5, y: 4.0),
                         size: CGSize(width: 2.2, height: 2.0))
                ]
            ))
        }
        return store
    }
}
