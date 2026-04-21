import Foundation
import AVFoundation
import Combine

@MainActor
final class AudioPlayer: NSObject, ObservableObject {
    @Published private(set) var isPlaying = false
    @Published private(set) var progress: Double = 0
    @Published private(set) var currentRecordingID: UUID?

    private var player: AVAudioPlayer?
    private var timer: Timer?

    func toggle(_ recording: HeartbeatRecording) {
        if currentRecordingID == recording.id, isPlaying {
            pause()
            return
        }
        if currentRecordingID == recording.id, let player {
            player.play()
            isPlaying = true
            startTimer()
            return
        }
        play(recording)
    }

    func play(_ recording: HeartbeatRecording) {
        stopTimer()
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            let player = try AVAudioPlayer(contentsOf: recording.fileURL)
            player.delegate = self
            player.prepareToPlay()
            guard player.play() else { return }
            self.player = player
            currentRecordingID = recording.id
            isPlaying = true
            progress = 0
            startTimer()
        } catch {
            print("AudioPlayer: \(error.localizedDescription)")
        }
    }

    func pause() {
        player?.pause()
        isPlaying = false
        stopTimer()
    }

    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
        progress = 0
        currentRecordingID = nil
        stopTimer()
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard let player, player.duration > 0 else { return }
        progress = player.currentTime / player.duration
    }
}

extension AudioPlayer: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.isPlaying = false
            self.progress = 0
            self.stopTimer()
        }
    }
}
