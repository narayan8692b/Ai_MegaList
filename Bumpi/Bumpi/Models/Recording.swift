import Foundation

struct HeartbeatRecording: Codable, Identifiable, Equatable {
    let id: UUID
    var title: String?
    let createdAt: Date
    var duration: TimeInterval
    var filename: String
    var detectedBPM: Int?

    init(
        id: UUID = UUID(),
        title: String? = nil,
        createdAt: Date = Date(),
        duration: TimeInterval,
        filename: String,
        detectedBPM: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.duration = duration
        self.filename = filename
        self.detectedBPM = detectedBPM
    }

    var fileURL: URL {
        RecordingStore.recordingsDirectory.appendingPathComponent(filename)
    }

    var displayDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: createdAt)
    }

    var displayTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: createdAt)
    }

    var durationString: String {
        let totalSeconds = Int(duration.rounded())
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
