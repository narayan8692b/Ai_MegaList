import Foundation

final class StorageService {
    static let shared = StorageService()

    private let fileManager = FileManager.default
    private let recordingsFileName = "recordings.json"

    private init() {
        try? fileManager.createDirectory(at: audioDirectory, withIntermediateDirectories: true)
    }

    var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    var audioDirectory: URL {
        documentsDirectory.appendingPathComponent("Audio", isDirectory: true)
    }

    var metadataURL: URL {
        documentsDirectory.appendingPathComponent(recordingsFileName)
    }

    func audioURL(for fileName: String) -> URL {
        audioDirectory.appendingPathComponent(fileName)
    }

    func load() -> [Recording] {
        guard fileManager.fileExists(atPath: metadataURL.path) else { return [] }
        do {
            let data = try Data(contentsOf: metadataURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([Recording].self, from: data)
        } catch {
            print("Failed to load recordings: \(error)")
            return []
        }
    }

    func save(_ recordings: [Recording]) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(recordings)
            try data.write(to: metadataURL, options: .atomic)
        } catch {
            print("Failed to save recordings: \(error)")
        }
    }

    func deleteAudio(fileName: String) {
        let url = audioURL(for: fileName)
        try? fileManager.removeItem(at: url)
    }
}
