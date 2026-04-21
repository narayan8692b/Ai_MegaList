import SwiftUI

struct RecorderSheet: View {
    @EnvironmentObject var store: RecordingsStore
    @EnvironmentObject var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    @StateObject private var recorder = AudioRecorderService()
    @State private var title: String = ""
    @State private var permissionDenied = false
    @State private var error: String?
    @State private var isProcessing = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                VStack(spacing: 24) {
                    Spacer()

                    Text(formattedElapsed)
                        .font(.system(size: 56, weight: .semibold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                        .monospacedDigit()

                    MeterBars(level: recorder.meterLevel, isActive: recorder.isRecording)
                        .frame(height: 48)
                        .padding(.horizontal, 40)

                    TextField("Recording title (optional)", text: $title)
                        .textFieldStyle(.plain)
                        .padding(14)
                        .cardBackground()
                        .foregroundColor(Theme.textPrimary)
                        .padding(.horizontal, 32)

                    Spacer()

                    mainButton

                    if let error {
                        Text(error)
                            .font(.footnote)
                            .foregroundColor(.red.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    Spacer().frame(height: 24)
                }
            }
            .navigationTitle("New Recording")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        if recorder.isRecording { recorder.cancel() }
                        dismiss()
                    }
                    .foregroundColor(Theme.textSecondary)
                }
            }
            .alert("Microphone Access Needed",
                   isPresented: $permissionDenied) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please enable microphone access in Settings to record audio.")
            }
            .disabled(isProcessing)
            .overlay {
                if isProcessing {
                    ProcessingOverlay()
                }
            }
        }
    }

    private var mainButton: some View {
        Button {
            Task { await toggle() }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: recorder.isRecording ? "stop.fill" : "mic.fill")
                Text(recorder.isRecording ? "Stop & Save" : "Start Recording")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(recorder.isRecording ? Color.red : Theme.accent)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.horizontal, 32)
            .shadow(color: (recorder.isRecording ? Color.red : Theme.accent).opacity(0.35), radius: 12, x: 0, y: 6)
        }
    }

    private var formattedElapsed: String {
        let totalMillis = Int(recorder.elapsed * 10)
        let tenths = totalMillis % 10
        let totalSeconds = totalMillis / 10
        let seconds = totalSeconds % 60
        let minutes = totalSeconds / 60
        return String(format: "%02d:%02d.%d", minutes, seconds, tenths)
    }

    private func toggle() async {
        error = nil
        if recorder.isRecording {
            await finish()
        } else {
            let granted = await recorder.requestPermission()
            guard granted else {
                permissionDenied = true
                return
            }
            do {
                _ = try recorder.start()
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    private func finish() async {
        guard let result = recorder.stop() else { return }
        isProcessing = true
        defer { isProcessing = false }

        let fileName = result.url.lastPathComponent
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalTitle = trimmedTitle.isEmpty ? defaultTitle() : trimmedTitle

        var recording = Recording(
            title: finalTitle,
            duration: result.duration,
            audioFileName: fileName,
            languageCode: settings.defaultLanguageCode
        )

        if settings.autoTranscribe {
            do {
                let text = try await TranscriptionService.shared.transcribe(
                    url: result.url,
                    languageCode: recording.languageCode
                )
                recording.transcription = text
                if settings.generateSummaryOnSave {
                    let analysis = AIService.shared.analyze(transcription: text)
                    recording.summary = analysis.summary
                    recording.bulletPoints = analysis.bulletPoints
                    recording.flashCards = analysis.flashCards
                    recording.quiz = analysis.quiz
                }
            } catch {
                self.error = "Saved, but transcription failed: \(error.localizedDescription)"
            }
        }

        store.add(recording)
        dismiss()
    }

    private func defaultTitle() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy h:mm a"
        return "Recording \(formatter.string(from: Date()))"
    }
}

private struct MeterBars: View {
    var level: Float
    var isActive: Bool

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 4) {
                ForEach(0..<24, id: \.self) { i in
                    let baseline: CGFloat = isActive
                        ? CGFloat(barHeight(for: i))
                        : 4
                    Capsule()
                        .fill(isActive ? Theme.accent : Theme.pillStroke)
                        .frame(width: (geo.size.width - (23 * 4)) / 24, height: baseline)
                }
            }
            .frame(maxHeight: .infinity, alignment: .center)
            .animation(.easeOut(duration: 0.12), value: level)
        }
    }

    private func barHeight(for index: Int) -> CGFloat {
        let normalized = CGFloat(level)
        let wave = sin(CGFloat(index) * 0.6) * 0.4 + 0.6
        return max(4, normalized * 40 * wave)
    }
}

private struct ProcessingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 14) {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.4)
                Text("Transcribing & summarizing...")
                    .font(.footnote)
                    .foregroundColor(.white)
            }
            .padding(24)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}
