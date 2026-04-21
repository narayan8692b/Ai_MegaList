import Foundation
import Combine

@MainActor
final class RecordingStore: ObservableObject {
    @Published private(set) var recordings: [HeartbeatRecording] = []

    private let indexFileName = "recordings.json"

    static var recordingsDirectory: URL {
        let fm = FileManager.default
        let base = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("Recordings", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    private var indexURL: URL {
        Self.recordingsDirectory.appendingPathComponent(indexFileName)
    }

    init() {
        load()
    }

    func add(_ recording: HeartbeatRecording) {
        recordings.insert(recording, at: 0)
        persist()
    }

    func delete(_ recording: HeartbeatRecording) {
        if let idx = recordings.firstIndex(where: { $0.id == recording.id }) {
            recordings.remove(at: idx)
        }
        try? FileManager.default.removeItem(at: recording.fileURL)
        persist()
    }

    func rename(_ recording: HeartbeatRecording, to newTitle: String) {
        guard let idx = recordings.firstIndex(where: { $0.id == recording.id }) else { return }
        recordings[idx].title = newTitle
        persist()
    }

    private func load() {
        guard let data = try? Data(contentsOf: indexURL) else { return }
        if let decoded = try? JSONDecoder().decode([HeartbeatRecording].self, from: data) {
            recordings = decoded.sorted { $0.createdAt > $1.createdAt }
        }
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(recordings)
            try data.write(to: indexURL, options: .atomic)
        } catch {
            print("RecordingStore: failed to persist \(error)")
        }
    }
}
