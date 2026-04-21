import Foundation
import AVFoundation
import Combine

@MainActor
final class AudioRecorderService: NSObject, ObservableObject {
    @Published private(set) var isRecording = false
    @Published private(set) var elapsed: TimeInterval = 0
    @Published private(set) var meterLevel: Float = 0

    private var recorder: AVAudioRecorder?
    private var timer: Timer?
    private var startDate: Date?

    private(set) var currentFileURL: URL?

    func requestPermission() async -> Bool {
        await withCheckedContinuation { cont in
            AVAudioApplication.requestRecordPermission { granted in
                cont.resume(returning: granted)
            }
        }
    }

    func start() throws -> URL {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
        try session.setActive(true)

        let fileName = "rec-\(UUID().uuidString).m4a"
        let url = StorageService.shared.audioDirectory.appendingPathComponent(fileName)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        let recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder.isMeteringEnabled = true
        recorder.delegate = self
        guard recorder.record() else {
            throw NSError(domain: "AudioRecorder", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not start recording"])
        }

        self.recorder = recorder
        self.currentFileURL = url
        self.startDate = Date()
        self.isRecording = true
        self.elapsed = 0
        startTimer()
        return url
    }

    func stop() -> (url: URL, duration: TimeInterval)? {
        guard let recorder, let url = currentFileURL else { return nil }
        let duration = recorder.currentTime
        recorder.stop()
        stopTimer()
        isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        self.recorder = nil
        self.currentFileURL = nil
        return (url, duration)
    }

    func cancel() {
        guard let recorder, let url = currentFileURL else { return }
        recorder.stop()
        try? FileManager.default.removeItem(at: url)
        stopTimer()
        isRecording = false
        self.recorder = nil
        self.currentFileURL = nil
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let recorder = self.recorder else { return }
                recorder.updateMeters()
                let power = recorder.averagePower(forChannel: 0)
                let normalized = max(0, min(1, (power + 60) / 60))
                self.meterLevel = normalized
                if let start = self.startDate {
                    self.elapsed = Date().timeIntervalSince(start)
                }
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        meterLevel = 0
    }
}

extension AudioRecorderService: AVAudioRecorderDelegate {}
