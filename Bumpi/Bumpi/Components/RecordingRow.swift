import SwiftUI

struct RecordingRow: View {
    let recording: HeartbeatRecording
    let isPlaying: Bool
    let progress: Double
    let onToggle: () -> Void
    let onShare: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .fill(BumpiTheme.softPink)
                        .frame(width: 44, height: 44)

                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(BumpiTheme.primary)
                        .offset(x: isPlaying ? 0 : 1)
                }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(recording.title ?? recording.displayDate)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(BumpiTheme.textPrimary)
                    if let bpm = recording.detectedBPM {
                        Text("· \(bpm) BPM")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(BumpiTheme.primary)
                    }
                }

                HStack(spacing: 6) {
                    Text("\(recording.displayTime) · \(recording.durationString)")
                        .font(.system(size: 12))
                        .foregroundColor(BumpiTheme.textSecondary)
                }

                if isPlaying {
                    ProgressView(value: progress)
                        .tint(BumpiTheme.primary)
                        .frame(height: 3)
                        .padding(.top, 2)
                }
            }

            Spacer()

            HStack(spacing: 6) {
                Button(action: onShare) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(BumpiTheme.textSecondary)
                        .frame(width: 34, height: 34)
                        .background(BumpiTheme.softPink.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(BumpiTheme.primary)
                        .frame(width: 34, height: 34)
                        .background(BumpiTheme.softPink.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}
