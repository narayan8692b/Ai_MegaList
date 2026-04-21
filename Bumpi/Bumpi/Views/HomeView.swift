import SwiftUI
import UIKit

struct HomeView: View {
    @EnvironmentObject var profileStore: BabyProfileStore
    @EnvironmentObject var recordingStore: RecordingStore
    @StateObject private var player = AudioPlayer()

    @State private var showSettings = false
    @State private var showRecorder = false
    @State private var now = Date()

    private let clock = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack(alignment: .bottom) {
            BumpiTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    header
                    babyCard
                    recordingsSection
                    Color.clear.frame(height: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }

            startButton
        }
        .onReceive(clock) { _ in now = Date() }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(profileStore)
                .environmentObject(recordingStore)
        }
        .fullScreenCover(isPresented: $showRecorder) {
            RecordingView()
                .environmentObject(recordingStore)
        }
    }

    private var header: some View {
        HStack {
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(BumpiTheme.primary)
                    .padding(10)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
            }

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: "heart.fill")
                    .foregroundColor(BumpiTheme.primary)
                if let name = profileStore.profile?.name {
                    Text(name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(BumpiTheme.textPrimary)
                }
                Text("✨")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.white)
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)

            Spacer()

            Button {
                // Info/about tapped
            } label: {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(BumpiTheme.primary)
                    .padding(10)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
            }
        }
    }

    private var babyCard: some View {
        VStack(spacing: 16) {
            BabyIllustrationView(pulse: true, size: 200)
                .padding(.top, 20)

            if let profile = profileStore.profile {
                let countdown = DueDateCountdown.from(dueDate: profile.dueDate, now: now)
                VStack(spacing: 10) {
                    Text(countdown.isPast ? "\(profile.name) is here!" : "Meeting \(profile.name) in")
                        .font(.system(size: 14))
                        .foregroundColor(BumpiTheme.textSecondary)

                    if !countdown.isPast {
                        HStack(alignment: .lastTextBaseline, spacing: 8) {
                            countdownUnit(value: countdown.days, unit: "d")
                            Text(":").foregroundColor(BumpiTheme.textSecondary)
                            countdownUnit(value: countdown.hours, unit: "h")
                            Text(":").foregroundColor(BumpiTheme.textSecondary)
                            countdownUnit(value: countdown.minutes, unit: "m")
                        }
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
            }
        }
    }

    private func countdownUnit(value: Int, unit: String) -> some View {
        HStack(alignment: .lastTextBaseline, spacing: 2) {
            Text("\(value)")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(BumpiTheme.textPrimary)
            Text(unit)
                .font(.system(size: 14))
                .foregroundColor(BumpiTheme.textSecondary)
        }
    }

    private var recordingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if recordingStore.recordings.isEmpty {
                emptyState
            } else {
                HStack {
                    Text("Recordings")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(BumpiTheme.textPrimary)
                    Spacer()
                    Text("\(recordingStore.recordings.count)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(BumpiTheme.textSecondary)
                }

                VStack(spacing: 10) {
                    ForEach(recordingStore.recordings) { recording in
                        RecordingRow(
                            recording: recording,
                            isPlaying: player.currentRecordingID == recording.id && player.isPlaying,
                            progress: player.currentRecordingID == recording.id ? player.progress : 0,
                            onToggle: { player.toggle(recording) },
                            onShare: { share(recording) },
                            onDelete: { delete(recording) }
                        )
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "waveform")
                .font(.system(size: 34))
                .foregroundColor(BumpiTheme.primary.opacity(0.5))
            Text("No recordings yet")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(BumpiTheme.textPrimary)
            Text("Tap Start Listening below to capture your first heartbeat.")
                .font(.system(size: 13))
                .foregroundColor(BumpiTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var startButton: some View {
        Button {
            showRecorder = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "mic.fill")
                Text("Start Listening")
            }
        }
        .buttonStyle(BumpiPrimaryButtonStyle())
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }

    private func share(_ recording: HeartbeatRecording) {
        let av = UIActivityViewController(activityItems: [recording.fileURL], applicationActivities: nil)
        UIApplication.shared.presentTopMost(av)
    }

    private func delete(_ recording: HeartbeatRecording) {
        if player.currentRecordingID == recording.id {
            player.stop()
        }
        recordingStore.delete(recording)
    }
}

private extension UIApplication {
    func presentTopMost(_ controller: UIViewController) {
        guard let scene = connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController else { return }
        var top = root
        while let presented = top.presentedViewController { top = presented }
        top.present(controller, animated: true)
    }
}
