import SwiftUI
import UIKit

struct RecordingView: View {
    @EnvironmentObject var recordingStore: RecordingStore
    @Environment(\.dismiss) private var dismiss
    @StateObject private var recorder = AudioRecorder()

    @State private var showSavedToast = false
    @State private var showPermissionAlert = false

    var body: some View {
        ZStack {
            BumpiTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                Spacer()
                illustration
                Spacer()
                waveformSection
                Spacer()
                controls
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)

            if showSavedToast {
                toast
            }
        }
        .onAppear(perform: start)
        .onDisappear { recorder.cancel() }
        .alert("Microphone access needed", isPresented: $showPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) { dismiss() }
        } message: {
            Text("To listen for your baby's heartbeat, Bumpi needs permission to use the microphone.")
        }
    }

    private var header: some View {
        HStack {
            Button {
                recorder.cancel()
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(BumpiTheme.textPrimary)
                    .padding(10)
                    .background(Color.white.opacity(0.8))
                    .clipShape(Circle())
            }

            Spacer()

            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(BumpiTheme.textPrimary)

            Spacer()

            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.top, 16)
    }

    private var title: String {
        switch recorder.state {
        case .recording: return "Recording"
        case .finished: return "Saved"
        default: return "Listen"
        }
    }

    private var illustration: some View {
        BabyIllustrationView(pulse: isRecording, size: 240)
    }

    private var waveformSection: some View {
        VStack(spacing: 20) {
            WaveformView(levels: recorder.levels)
                .frame(height: 80)
                .padding(.horizontal, 12)

            VStack(spacing: 6) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 14))
                    .foregroundColor(BumpiTheme.primary)

                Text(statusText)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(BumpiTheme.textPrimary)

                Text(subStatusText)
                    .font(.system(size: 13))
                    .foregroundColor(BumpiTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if isRecording, recorder.detectedBPM > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(BumpiTheme.primary)
                    Text("\(recorder.detectedBPM) BPM")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(BumpiTheme.textPrimary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.white)
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
                .transition(.scale.combined(with: .opacity))
            }
        }
    }

    private var controls: some View {
        VStack(spacing: 16) {
            Text(formattedElapsed)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundColor(BumpiTheme.textPrimary)
                .monospacedDigit()

            Button(action: primaryAction) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 84, height: 84)
                        .shadow(color: BumpiTheme.primary.opacity(0.3), radius: 16, x: 0, y: 8)

                    if isRecording {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(BumpiTheme.primary)
                            .frame(width: 26, height: 26)
                    } else {
                        Circle()
                            .fill(BumpiTheme.primary)
                            .frame(width: 64, height: 64)
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(isPreparingOrFailed)

            Text(isRecording ? "Tap to stop and save" : "Tap to start recording")
                .font(.system(size: 13))
                .foregroundColor(BumpiTheme.textSecondary)
        }
    }

    private var toast: some View {
        VStack {
            Spacer()
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Recording saved")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(BumpiTheme.textPrimary)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(Color.white)
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 4)
            .padding(.bottom, 140)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private var isRecording: Bool {
        if case .recording = recorder.state { return true }
        return false
    }

    private var isPreparingOrFailed: Bool {
        switch recorder.state {
        case .preparing, .failed, .denied: return true
        default: return false
        }
    }

    private var formattedElapsed: String {
        let total = Int(recorder.elapsed.rounded())
        return String(format: "%02d:%02d", total / 60, total % 60)
    }

    private var statusText: String {
        switch recorder.state {
        case .recording: return "Listening to heartbeat..."
        case .preparing: return "Getting ready..."
        case .idle: return "Ready to listen"
        case .finished: return "Got it!"
        case .denied: return "Microphone access denied"
        case .failed: return "Something went wrong"
        }
    }

    private var subStatusText: String {
        switch recorder.state {
        case .recording: return "Keep your phone on your belly"
        case .preparing: return "Calibrating microphone"
        case .idle: return "Place your phone on your belly and tap the button below"
        case .finished: return "Your recording has been saved"
        case .denied: return "Enable microphone access in Settings"
        case .failed(let msg): return msg
        }
    }

    private func start() {
        recorder.start()
    }

    private func primaryAction() {
        switch recorder.state {
        case .idle:
            recorder.start()
        case .recording:
            stopAndSave()
        case .denied:
            showPermissionAlert = true
        default:
            break
        }
    }

    private func stopAndSave() {
        guard let recording = recorder.stop() else { return }
        recordingStore.add(recording)
        withAnimation(.spring()) { showSavedToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation { showSavedToast = false }
            dismiss()
        }
    }
}
