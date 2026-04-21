import Foundation
import Combine

@MainActor
final class RecordingsStore: ObservableObject {
    @Published var recordings: [Recording] = []
    @Published var searchText: String = ""
    @Published var sortNewestFirst: Bool = true

    private let storage = StorageService.shared

    init() {
        load()
    }

    func load() {
        recordings = storage.load().sorted(by: { $0.createdAt > $1.createdAt })
    }

    var filteredRecordings: [Recording] {
        let filtered: [Recording]
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if query.isEmpty {
            filtered = recordings
        } else {
            filtered = recordings.filter {
                $0.title.lowercased().contains(query) ||
                $0.transcription.lowercased().contains(query) ||
                $0.summary.lowercased().contains(query)
            }
        }
        return sortNewestFirst
            ? filtered.sorted(by: { $0.createdAt > $1.createdAt })
            : filtered.sorted(by: { $0.createdAt < $1.createdAt })
    }

    func add(_ recording: Recording) {
        recordings.insert(recording, at: 0)
        persist()
    }

    func update(_ recording: Recording) {
        guard let idx = recordings.firstIndex(where: { $0.id == recording.id }) else { return }
        recordings[idx] = recording
        persist()
    }

    func delete(_ recording: Recording) {
        storage.deleteAudio(fileName: recording.audioFileName)
        recordings.removeAll(where: { $0.id == recording.id })
        persist()
    }

    func delete(at offsets: IndexSet) {
        let toDelete = offsets.map { filteredRecordings[$0] }
        for rec in toDelete { delete(rec) }
    }

    private func persist() {
        storage.save(recordings)
    }
}
