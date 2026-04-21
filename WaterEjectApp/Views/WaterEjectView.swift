import SwiftUI

struct WaterEjectView: View {

    @StateObject private var engine = ToneAudioEngine()

    @State private var currentCycle:   Int    = 0
    @State private var cycleProgress:  Double = 0
    @State private var animating:      Bool   = false
    @State private var cycleTimer:     Timer? = nil

    private let totalCycles    = 5
    private let cycleDuration  = 10.0   // seconds per cycle
    private let tickInterval   = 0.05

    // MARK: - Body

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    statusRow
                    cycleCard
                    speakerAnimation
                    actionButton
                    infoCard
                    Spacer(minLength: 24)
                }
                .padding(.top, 8)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Water Eject")
        }
        .onDisappear { stopEject() }
    }

    // MARK: - Sub-views

    private var statusRow: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(engine.isPlaying ? Color.blue : Color(.systemGray4))
                .frame(width: 10, height: 10)
                .overlay(
                    Circle()
                        .stroke(Color.blue.opacity(0.35), lineWidth: 5)
                        .scaleEffect(animating ? 2.2 : 1)
                        .opacity(animating ? 0 : 1)
                        .animation(
                            engine.isPlaying
                                ? .easeOut(duration: 1.0).repeatForever(autoreverses: false)
                                : .default,
                            value: animating
                        )
                )

            Text(statusLabel)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 4)
    }

    private var cycleCard: some View {
        VStack(spacing: 14) {
            Text(engine.isPlaying
                 ? "Cycle \(currentCycle) / \(totalCycles)"
                 : "Cycle — / \(totalCycles)")
                .font(.headline)

            ProgressView(value: cycleProgress)
                .tint(.blue)
                .scaleEffect(x: 1, y: 1.8, anchor: .center)

            HStack(spacing: 20) {
                Label("Volume at 100%", systemImage: "speaker.wave.2.fill")
                Label("Point speaker down", systemImage: "arrow.down")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        .padding(.horizontal)
    }

    private var speakerAnimation: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .stroke(Color.blue.opacity(0.25), lineWidth: 2)
                    .frame(width: CGFloat(80 + i * 44), height: CGFloat(80 + i * 44))
                    .scaleEffect(animating ? 1.6 : 1)
                    .opacity(animating ? 0 : 1)
                    .animation(
                        engine.isPlaying
                            ? .easeOut(duration: 1.4)
                                .repeatForever(autoreverses: false)
                                .delay(Double(i) * 0.35)
                            : .default,
                        value: animating
                    )
            }

            Image(systemName: "speaker.wave.3.fill")
                .font(.system(size: 52))
                .foregroundColor(engine.isPlaying ? .blue : Color(.systemGray3))
        }
        .frame(height: 180)
    }

    private var actionButton: some View {
        Button(action: toggle) {
            HStack(spacing: 10) {
                Image(systemName: engine.isPlaying ? "stop.fill" : "play.fill")
                Text(buttonLabel)
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(engine.isPlaying ? Color.red : Color.blue)
            .cornerRadius(14)
        }
        .padding(.horizontal)
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("How it works", systemImage: "info.circle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.blue)
            Text("Plays a 165 Hz low-frequency sine wave at full gain. The vibrations dislodge water droplets trapped in the speaker grille. Run all 5 cycles for best results — keep your device pointed downward.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        .padding(.horizontal)
    }

    // MARK: - Helpers

    private var statusLabel: String {
        if engine.isPlaying          { return "Ejecting Water…" }
        if currentCycle >= totalCycles { return "Complete! Speaker Cleared" }
        return "Ready to Eject Water"
    }

    private var buttonLabel: String {
        if engine.isPlaying          { return "Stop" }
        if currentCycle >= totalCycles { return "Run Again" }
        return "Start Ejecting"
    }

    // MARK: - Actions

    private func toggle() {
        engine.isPlaying ? stopEject() : startEject()
    }

    private func startEject() {
        currentCycle  = 0
        cycleProgress = 0
        animating     = true

        engine.frequency = 165
        engine.waveform  = .sine
        engine.volume    = 1.0
        engine.channel   = .both
        engine.balance   = 0
        engine.start()

        var elapsed = 0.0
        currentCycle = 1

        cycleTimer = Timer.scheduledTimer(withTimeInterval: tickInterval, repeats: true) { t in
            elapsed       += self.tickInterval
            let inCycle    = elapsed.truncatingRemainder(dividingBy: self.cycleDuration)
            self.cycleProgress = inCycle / self.cycleDuration
            self.currentCycle  = min(Int(elapsed / self.cycleDuration) + 1, self.totalCycles)

            if elapsed >= Double(self.totalCycles) * self.cycleDuration {
                t.invalidate()
                self.cycleTimer    = nil
                self.cycleProgress = 1.0
                self.engine.stop()
                self.animating = false
            }
        }
    }

    private func stopEject() {
        cycleTimer?.invalidate()
        cycleTimer    = nil
        engine.stop()
        animating     = false
        cycleProgress = 0
    }
}
