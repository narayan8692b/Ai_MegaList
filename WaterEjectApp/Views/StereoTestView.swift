import SwiftUI

struct StereoTestView: View {

    @StateObject private var engine = ToneAudioEngine()

    @State private var selectedChannel: StereoChannel = .both
    @State private var balance: Double = 0
    @State private var volume:  Double = 0.7

    private var leftActive:  Bool { engine.isPlaying && selectedChannel != .right }
    private var rightActive: Bool { engine.isPlaying && selectedChannel != .left  }

    private var balanceLabel: String {
        if balance < -0.05 { return "Left" }
        if balance >  0.05 { return "Right" }
        return "Center"
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    channelCircles
                    channelPickerCard
                    playButton
                    balanceCard
                    volumeCard
                    infoCard
                    Spacer(minLength: 24)
                }
                .padding(.top, 16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Stereo Test")
        }
        .onDisappear { engine.stop() }
    }

    // MARK: - Sub-views

    private var channelCircles: some View {
        HStack(spacing: 40) {
            ChannelCircle(letter: "L", active: leftActive)
            ChannelCircle(letter: "R", active: rightActive)
        }
    }

    private var channelPickerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Channel").font(.subheadline.weight(.medium))

            HStack(spacing: 0) {
                ForEach(StereoChannel.allCases) { ch in
                    Button {
                        selectedChannel  = ch
                        engine.channel   = ch
                    } label: {
                        Text(ch.rawValue)
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(selectedChannel == ch ? Color.blue : Color(.systemGray6))
                            .foregroundColor(selectedChannel == ch ? .white : .primary)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
        .padding(.horizontal)
    }

    private var playButton: some View {
        Button(action: toggleStereo) {
            Image(systemName: engine.isPlaying ? "stop.fill" : "play.fill")
                .font(.system(size: 28))
                .foregroundColor(.white)
                .frame(width: 72, height: 72)
                .background(engine.isPlaying ? Color.red : Color.blue)
                .clipShape(Circle())
                .shadow(color: Color.blue.opacity(0.35), radius: 14, x: 0, y: 4)
        }
    }

    private var balanceCard: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Balance").font(.subheadline.weight(.medium))
                Spacer()
                Text(balanceLabel)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
            Slider(value: $balance, in: -1...1) { _ in
                engine.balance = Float(balance)
            }
            .tint(.blue)
            HStack {
                Text("Left").font(.caption2).foregroundColor(.secondary)
                Spacer()
                Text("Right").font(.caption2).foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
        .padding(.horizontal)
    }

    private var volumeCard: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Volume").font(.subheadline.weight(.medium))
                Spacer()
                Text("\(Int(volume * 100))%")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
            Slider(value: $volume, in: 0...1) { _ in
                engine.volume = Float(volume)
            }
            .tint(.blue)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
        .padding(.horizontal)
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Test your speakers", systemImage: "info.circle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.blue)
            Text("Play a 1 kHz sine tone through the left, right, or both channels to verify that your stereo speakers are working correctly and balanced.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
        .padding(.horizontal)
    }

    // MARK: - Actions

    private func toggleStereo() {
        if engine.isPlaying {
            engine.stop()
        } else {
            engine.frequency = 1000
            engine.waveform  = .sine
            engine.volume    = Float(volume)
            engine.channel   = selectedChannel
            engine.balance   = Float(balance)
            engine.start()
        }
    }
}

// MARK: - Channel Circle

struct ChannelCircle: View {
    let letter: String
    let active: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(active ? Color.blue.opacity(0.12) : Color(.systemGray6))
                .frame(width: 88, height: 88)
            Circle()
                .stroke(active ? Color.blue : Color(.systemGray4), lineWidth: 2)
                .frame(width: 88, height: 88)
            Text(letter)
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(active ? .blue : Color(.systemGray3))
        }
        .animation(.easeInOut(duration: 0.25), value: active)
    }
}
