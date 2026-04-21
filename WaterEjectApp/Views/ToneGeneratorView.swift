import SwiftUI

struct ToneGeneratorView: View {

    @StateObject private var engine = ToneAudioEngine()

    @State private var frequency:       Double       = 165
    @State private var volume:          Double       = 0.8
    @State private var selectedWaveform: WaveformType = .sine
    @State private var activePresetFreq: Double?     = 165

    private let presets: [(label: String, sub: String, freq: Double)] = [
        ("165 Hz", "Water Eject", 165),
        ("500 Hz", "Medium",      500),
        ("1 kHz",  "High",        1000),
        ("5 kHz",  "Very High",   5000),
    ]

    private var freqLabel: String {
        frequency >= 1000
            ? String(format: "%.0f kHz", frequency / 1000)
            : String(format: "%.0f Hz",  frequency)
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 18) {
                    frequencyCard
                    presetsCard
                    waveformPreviewCard
                    waveformTypeCard
                    volumeCard
                    Spacer(minLength: 24)
                }
                .padding(.vertical, 10)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Tone Generator")
        }
        .onDisappear { engine.stop() }
    }

    // MARK: - Cards

    private var frequencyCard: some View {
        card {
            VStack(spacing: 10) {
                HStack {
                    Text("Frequency").font(.subheadline.weight(.medium))
                    Spacer()
                    valueBadge(freqLabel)
                }
                Slider(value: $frequency, in: 20...20000, step: 1) { _ in
                    engine.frequency    = Float(frequency)
                    activePresetFreq    = nil
                }
                .tint(.blue)
                HStack {
                    Text("20 Hz").font(.caption2).foregroundColor(.secondary)
                    Spacer()
                    Text("20 kHz").font(.caption2).foregroundColor(.secondary)
                }
            }
        }
    }

    private var presetsCard: some View {
        card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Presets").font(.subheadline.weight(.medium))
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                    ForEach(presets, id: \.freq) { p in
                        Button {
                            frequency        = p.freq
                            activePresetFreq = p.freq
                            engine.frequency = Float(p.freq)
                        } label: {
                            let active = activePresetFreq == p.freq
                            VStack(spacing: 2) {
                                Text(p.label).font(.caption.weight(.semibold))
                                Text(p.sub).font(.system(size: 9))
                                    .foregroundColor(active ? .white.opacity(0.8) : .secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(active ? Color.blue : Color(.systemGray6))
                            .foregroundColor(active ? .white : .primary)
                            .cornerRadius(10)
                        }
                    }
                }
            }
        }
    }

    private var waveformPreviewCard: some View {
        card {
            WaveformPreview(waveform: selectedWaveform)
                .frame(height: 56)
                .frame(maxWidth: .infinity)
        }
    }

    private var waveformTypeCard: some View {
        card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Waveform Type").font(.subheadline.weight(.medium))
                HStack(spacing: 10) {
                    ForEach(WaveformType.allCases) { wf in
                        Button {
                            selectedWaveform = wf
                            engine.waveform  = wf
                        } label: {
                            WaveformIcon(type: wf)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(selectedWaveform == wf ? Color.blue : Color(.systemGray6))
                                .foregroundColor(selectedWaveform == wf ? .white : .primary)
                                .cornerRadius(10)
                        }
                    }
                }
            }
        }
    }

    private var volumeCard: some View {
        card {
            VStack(spacing: 10) {
                HStack {
                    Text("Volume").font(.subheadline.weight(.medium))
                    Spacer()
                    valueBadge("\(Int(volume * 100))%")
                }
                HStack(spacing: 14) {
                    Slider(value: $volume, in: 0...1) { _ in
                        engine.volume = Float(volume)
                    }
                    .tint(.blue)

                    Button(action: toggleTone) {
                        Image(systemName: engine.isPlaying ? "stop.fill" : "play.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                            .frame(width: 46, height: 46)
                            .background(engine.isPlaying ? Color.red : Color.blue)
                            .clipShape(Circle())
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
            .padding(.horizontal)
    }

    private func valueBadge(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundColor(.blue)
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
    }

    private func toggleTone() {
        if engine.isPlaying {
            engine.stop()
        } else {
            engine.frequency = Float(frequency)
            engine.waveform  = selectedWaveform
            engine.volume    = Float(volume)
            engine.channel   = .both
            engine.balance   = 0
            engine.start()
        }
    }
}

// MARK: - Waveform Preview

struct WaveformPreview: View {
    let waveform: WaveformType

    var body: some View {
        GeometryReader { geo in
            Path { path in
                let w    = geo.size.width
                let h    = geo.size.height
                let mid  = h / 2
                let amp  = h * 0.38
                let cycles = 3.0

                path.move(to: CGPoint(x: 0, y: mid))
                for xi in 0...Int(w) {
                    let t     = Double(xi) / Double(w)
                    let phase = t * cycles * 2 * Double.pi
                    let y     = sampleWaveform(phase: phase)
                    let pt    = CGPoint(x: CGFloat(xi), y: mid - CGFloat(y) * amp)
                    xi == 0 ? path.move(to: pt) : path.addLine(to: pt)
                }
            }
            .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        }
    }

    private func sampleWaveform(phase: Double) -> Double {
        switch waveform {
        case .sine:
            return sin(phase)
        case .square:
            return phase.truncatingRemainder(dividingBy: 2 * .pi) < .pi ? 1 : -1
        case .triangle:
            let t = phase.truncatingRemainder(dividingBy: 2 * .pi) / (2 * .pi)
            return t < 0.5 ? 4 * t - 1 : 3 - 4 * t
        case .sawtooth:
            let norm = phase.truncatingRemainder(dividingBy: 2 * .pi)
            return 1.0 - norm / .pi
        }
    }
}

// MARK: - Waveform Icon

struct WaveformIcon: View {
    let type: WaveformType

    var body: some View {
        GeometryReader { geo in
            let w   = geo.size.width - 8
            let h   = geo.size.height
            let mid = h / 2
            let amp = mid * 0.65
            let ox: CGFloat = 4

            Path { p in
                switch type {
                case .sine:
                    p.move(to: CGPoint(x: ox, y: mid))
                    for xi in 0...Int(w) {
                        let t = Double(xi) / Double(w)
                        let y = sin(t * 2 * .pi)
                        let pt = CGPoint(x: CGFloat(xi) + ox, y: mid - CGFloat(y) * amp)
                        xi == 0 ? p.move(to: pt) : p.addLine(to: pt)
                    }
                case .square:
                    p.move(to: CGPoint(x: ox,          y: mid - amp))
                    p.addLine(to: CGPoint(x: w/2 + ox, y: mid - amp))
                    p.addLine(to: CGPoint(x: w/2 + ox, y: mid + amp))
                    p.addLine(to: CGPoint(x: w   + ox, y: mid + amp))
                case .triangle:
                    p.move(to:    CGPoint(x: ox,          y: mid))
                    p.addLine(to: CGPoint(x: w/4   + ox,  y: mid - amp))
                    p.addLine(to: CGPoint(x: w/2   + ox,  y: mid))
                    p.addLine(to: CGPoint(x: w*3/4 + ox,  y: mid + amp))
                    p.addLine(to: CGPoint(x: w     + ox,  y: mid))
                case .sawtooth:
                    p.move(to:    CGPoint(x: ox,          y: mid + amp))
                    p.addLine(to: CGPoint(x: w/2   + ox,  y: mid - amp))
                    p.addLine(to: CGPoint(x: w/2   + ox,  y: mid + amp))
                    p.addLine(to: CGPoint(x: w     + ox,  y: mid - amp))
                }
            }
            .stroke(Color.primary,
                    style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
        }
    }
}
