import Foundation
import AVFoundation
import Combine

@MainActor
final class AudioRecorder: NSObject, ObservableObject {
    enum RecorderState: Equatable {
        case idle
        case preparing
        case recording
        case finished(HeartbeatRecording)
        case denied
        case failed(String)
    }

    @Published private(set) var state: RecorderState = .idle
    @Published private(set) var elapsed: TimeInterval = 0
    @Published private(set) var levels: [CGFloat] = Array(repeating: 0.05, count: 48)
    @Published private(set) var detectedBPM: Int = 0

    private var recorder: AVAudioRecorder?
    private var meterTimer: Timer?
    private let detector = HeartbeatDetector()
    private var startDate: Date?
    private var currentFilename: String?

    func requestPermissionIfNeeded(_ completion: @escaping (Bool) -> Void) {
        let session = AVAudioSession.sharedInstance()
        switch session.recordPermission {
        case .granted:
            completion(true)
        case .denied:
            completion(false)
        case .undetermined:
            session.requestRecordPermission { granted in
                DispatchQueue.main.async { completion(granted) }
            }
        @unknown default:
            completion(false)
        }
    }

    func start() {
        state = .preparing
        requestPermissionIfNeeded { [weak self] granted in
            guard let self else { return }
            guard granted else {
                self.state = .denied
                return
            }
            self.beginRecording()
        }
    }

    private func beginRecording() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true, options: [])
        } catch {
            state = .failed("Audio session: \(error.localizedDescription)")
            return
        }

        let filename = "hb_\(Int(Date().timeIntervalSince1970)).m4a"
        let url = RecordingStore.recordingsDirectory.appendingPathComponent(filename)
        currentFilename = filename

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            let recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder.delegate = self
            recorder.isMeteringEnabled = true
            guard recorder.record() else {
                state = .failed("Could not start recording")
                return
            }
            self.recorder = recorder
            startDate = Date()
            elapsed = 0
            detector.reset()
            detectedBPM = 0
            startMetering()
            state = .recording
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func stop() -> HeartbeatRecording? {
        guard let recorder, state == .recording else { return nil }
        let duration = recorder.currentTime
        recorder.stop()
        stopMetering()

        guard let filename = currentFilename else { return nil }
        let bpm = detector.currentBPM
        let recording = HeartbeatRecording(
            duration: duration,
            filename: filename,
            detectedBPM: bpm > 0 ? bpm : nil
        )

        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        state = .finished(recording)
        self.recorder = nil
        return recording
    }

    func cancel() {
        recorder?.stop()
        if let url = recorder?.url {
            try? FileManager.default.removeItem(at: url)
        }
        stopMetering()
        recorder = nil
        state = .idle
        elapsed = 0
        levels = Array(repeating: 0.05, count: 48)
        detectedBPM = 0
    }

    private func startMetering() {
        meterTimer?.invalidate()
        meterTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    private func stopMetering() {
        meterTimer?.invalidate()
        meterTimer = nil
    }

    private func tick() {
        guard let recorder = recorder, let startDate else { return }
        recorder.updateMeters()
        let power = recorder.averagePower(forChannel: 0)
        let normalized = normalize(power: power)

        levels.removeFirst()
        levels.append(CGFloat(normalized))
        elapsed = Date().timeIntervalSince(startDate)

        detector.ingest(level: normalized, at: elapsed)
        detectedBPM = detector.currentBPM
    }

    private func normalize(power: Float) -> Float {
        let minDb: Float = -60
        if power < minDb { return 0 }
        if power >= 0 { return 1 }
        let value = (power - minDb) / -minDb
        return max(0, min(1, value))
    }
}

extension AudioRecorder: AVAudioRecorderDelegate {
    nonisolated func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        Task { @MainActor in
            self.state = .failed(error?.localizedDescription ?? "Recording error")
        }
    }
}
