import AVFoundation

final class DBMeterEngine: ObservableObject {

    @Published var isRecording: Bool  = false
    @Published var currentLevel: Float = 0   // approximate SPL 0–120 dB
    @Published var peakLevel:    Float = 0
    @Published var history:      [Float] = []

    var badge: String {
        switch currentLevel {
        case ..<55:  return "Safe"
        case ..<75:  return "Moderate"
        case ..<90:  return "Loud"
        default:     return "Danger"
        }
    }

    private var engine: AVAudioEngine?
    private let historyLimit = 80

    // MARK: - Public

    func start() {
        guard !isRecording else { return }
        configureSession()

        let eng = AVAudioEngine()
        engine  = eng

        let input  = eng.inputNode
        let format = input.outputFormat(forBus: 0)

        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            guard let self else { return }
            let level = self.rmsToSPL(buffer: buffer)
            DispatchQueue.main.async {
                self.currentLevel = level
                if level > self.peakLevel { self.peakLevel = level }
                self.history.append(level)
                if self.history.count > self.historyLimit { self.history.removeFirst() }
            }
        }

        do {
            try eng.start()
            DispatchQueue.main.async { self.isRecording = true }
        } catch {
            print("DBMeterEngine: engine.start() failed — \(error)")
        }
    }

    func stop() {
        engine?.inputNode.removeTap(onBus: 0)
        engine?.stop()
        engine = nil
        DispatchQueue.main.async { self.isRecording = false }
    }

    func resetPeak() { peakLevel = 0 }

    // MARK: - Private

    /// Converts buffer RMS to an approximate SPL value (0–120 dB).
    /// Maps dBFS –90 → 0 dB SPL, dBFS 0 → 90 dB SPL (rough approximation).
    private func rmsToSPL(buffer: AVAudioPCMBuffer) -> Float {
        guard
            let data = buffer.floatChannelData?[0],
            buffer.frameLength > 0
        else { return 0 }

        let count = Int(buffer.frameLength)
        var sum: Float = 0
        for i in 0..<count { let s = data[i]; sum += s * s }
        let rms   = sqrt(sum / Float(count))
        let dbFS  = 20 * log10(max(rms, 1e-9))
        return max(0, min(120, dbFS + 90))
    }

    private func configureSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playAndRecord,
                mode: .measurement,
                options: [.defaultToSpeaker, .allowBluetooth]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("DBMeterEngine: session configuration failed — \(error)")
        }
    }
}
