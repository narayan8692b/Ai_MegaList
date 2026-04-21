import AVFoundation

enum WaveformType: String, CaseIterable, Identifiable {
    case sine     = "Sine"
    case square   = "Square"
    case triangle = "Triangle"
    case sawtooth = "Sawtooth"

    var id: String { rawValue }
}

enum StereoChannel: String, CaseIterable, Identifiable {
    case left  = "Left"
    case both  = "Both"
    case right = "Right"

    var id: String { rawValue }
}

// Not thread-safe by design — written on main thread, read on audio thread.
// Acceptable for a demo app on ARM where stores/loads are atomic for scalar types.
final class ToneAudioEngine: ObservableObject {

    @Published var isPlaying = false

    var frequency: Float = 165.0
    var waveform:  WaveformType  = .sine
    var volume:    Float = 0.8
    var balance:   Float = 0.0   // -1 (full left) … 0 (center) … 1 (full right)
    var channel:   StereoChannel = .both

    private var engine:     AVAudioEngine?
    private var sourceNode: AVAudioSourceNode?
    private var phase:      Double = 0
    private let sampleRate: Double = 44100

    // MARK: - Public

    func start() {
        guard !isPlaying else { return }
        configureSession(forRecording: false)
        buildEngine()
    }

    func stop() {
        engine?.stop()
        if let node = sourceNode, let eng = engine { eng.detach(node) }
        sourceNode = nil
        engine     = nil
        DispatchQueue.main.async { self.isPlaying = false }
    }

    // MARK: - Private

    private func buildEngine() {
        let eng    = AVAudioEngine()
        engine     = eng
        phase      = 0

        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!

        let node = AVAudioSourceNode(format: format) { [weak self] _, _, frameCount, abl in
            guard let s = self else { return noErr }
            let ptr       = UnsafeMutableAudioBufferListPointer(abl)
            let phaseInc  = 2.0 * Double.pi * Double(s.frequency) / s.sampleRate
            let vol       = s.volume
            let wf        = s.waveform
            let bal       = s.balance
            let ch        = s.channel

            for frame in 0..<Int(frameCount) {
                let p = s.phase

                var sample: Float
                switch wf {
                case .sine:
                    sample = Float(sin(p))
                case .square:
                    sample = p < .pi ? 1.0 : -1.0
                case .triangle:
                    let t = p / (2 * .pi)
                    sample = Float(t < 0.5 ? 4 * t - 1 : 3 - 4 * t)
                case .sawtooth:
                    sample = Float(1.0 - p / .pi)
                }
                sample *= vol

                let lg: Float
                let rg: Float
                switch ch {
                case .left:
                    lg = 1; rg = 0
                case .right:
                    lg = 0; rg = 1
                case .both:
                    // Linear pan law: centre = full volume on both sides
                    lg = max(0, 1.0 - max(0, bal))
                    rg = max(0, 1.0 + min(0, bal))
                }

                if ptr.count >= 1 {
                    ptr[0].mData?.assumingMemoryBound(to: Float.self)[frame] = sample * lg
                }
                if ptr.count >= 2 {
                    ptr[1].mData?.assumingMemoryBound(to: Float.self)[frame] = sample * rg
                }

                s.phase += phaseInc
                if s.phase >= 2 * .pi { s.phase -= 2 * .pi }
            }
            return noErr
        }

        sourceNode = node
        eng.attach(node)
        eng.connect(node, to: eng.mainMixerNode, format: format)

        do {
            try eng.start()
            DispatchQueue.main.async { self.isPlaying = true }
        } catch {
            print("ToneAudioEngine: engine.start() failed — \(error)")
        }
    }

    func configureSession(forRecording: Bool) {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(
                .playAndRecord,
                mode: forRecording ? .measurement : .default,
                options: [.defaultToSpeaker, .allowBluetooth]
            )
            try session.setActive(true)
        } catch {
            print("ToneAudioEngine: session configuration failed — \(error)")
        }
    }
}
