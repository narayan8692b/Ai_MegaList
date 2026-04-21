import Foundation

/// Lightweight heartbeat-rate estimator that consumes microphone amplitude
/// samples and detects peaks spaced within the plausible fetal BPM range.
///
/// This is an approximation for UI feedback — a clinical Doppler device
/// performs actual ultrasonic demodulation. For in-app feedback we extract
/// rhythmic peaks from the low-frequency amplitude envelope.
final class HeartbeatDetector {
    private struct Peak { let time: TimeInterval }

    private let minBPM: Double = 80
    private let maxBPM: Double = 200
    private let envelopeWindow = 8

    private var envelope: [Float] = []
    private var peaks: [Peak] = []
    private var lastPeakTime: TimeInterval = -1
    private(set) var currentBPM: Int = 0

    func reset() {
        envelope.removeAll()
        peaks.removeAll()
        lastPeakTime = -1
        currentBPM = 0
    }

    func ingest(level: Float, at time: TimeInterval) {
        envelope.append(level)
        if envelope.count > envelopeWindow * 4 {
            envelope.removeFirst(envelope.count - envelopeWindow * 4)
        }

        guard envelope.count >= envelopeWindow else { return }

        let recent = envelope.suffix(envelopeWindow)
        let avg = recent.reduce(0, +) / Float(recent.count)
        let peakThreshold = avg * 1.5 + 0.08

        let minInterval = 60.0 / maxBPM
        let maxInterval = 60.0 / minBPM

        if level > peakThreshold, time - lastPeakTime > minInterval {
            if lastPeakTime > 0, time - lastPeakTime > maxInterval {
                peaks.removeAll()
            }
            peaks.append(Peak(time: time))
            lastPeakTime = time

            if peaks.count > 8 {
                peaks.removeFirst(peaks.count - 8)
            }

            recomputeBPM()
        }
    }

    private func recomputeBPM() {
        guard peaks.count >= 3 else { return }
        var intervals: [TimeInterval] = []
        for i in 1..<peaks.count {
            intervals.append(peaks[i].time - peaks[i - 1].time)
        }
        let avg = intervals.reduce(0, +) / Double(intervals.count)
        guard avg > 0 else { return }
        let bpm = 60.0 / avg
        if bpm >= minBPM && bpm <= maxBPM {
            currentBPM = Int(bpm.rounded())
        }
    }
}
