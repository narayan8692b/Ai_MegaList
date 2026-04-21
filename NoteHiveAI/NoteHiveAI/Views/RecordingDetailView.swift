import SwiftUI

enum DetailTab: String, CaseIterable, Identifiable {
    case transcription, summary, flashCards, bulletPoints, quiz
    var id: String { rawValue }

    var title: String {
        switch self {
        case .transcription: return "Transcription"
        case .summary: return "Summary"
        case .flashCards: return "Flash Cards"
        case .bulletPoints: return "Bullet Points"
        case .quiz: return "Quiz"
        }
    }

    var icon: String {
        switch self {
        case .transcription: return "character.book.closed"
        case .summary: return "doc.text"
        case .flashCards: return "rectangle.on.rectangle"
        case .bulletPoints: return "list.bullet"
        case .quiz: return "questionmark.circle"
        }
    }
}

struct RecordingDetailView: View {
    @EnvironmentObject var store: RecordingsStore
    @Environment(\.dismiss) private var dismiss

    let recordingID: UUID

    @StateObject private var player = AudioPlayerService()
    @State private var selectedTab: DetailTab = .transcription
    @State private var showLanguagePicker = false
    @State private var isRegenerating = false
    @State private var shareItem: URL?
    @State private var showCopyToast = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            if let recording = currentRecording {
                content(for: recording)
            } else {
                VStack {
                    Text("Recording not found")
                        .foregroundColor(Theme.textSecondary)
                }
            }
            if showCopyToast {
                VStack {
                    Spacer()
                    Text("Copied to clipboard")
                        .font(.footnote)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Theme.card)
                        .clipShape(Capsule())
                        .padding(.bottom, 40)
                }
                .transition(.opacity)
            }
        }
        .navigationTitle("Recording Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(Theme.textPrimary)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 14) {
                    Button(action: copyContent) {
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(Theme.textPrimary)
                    }
                    if let recording = currentRecording {
                        let url = StorageService.shared.audioURL(for: recording.audioFileName)
                        ShareLink(item: url) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(Theme.textPrimary)
                        }
                    }
                }
            }
        }
        .onAppear { loadPlayer() }
        .onDisappear { player.stop() }
        .sheet(isPresented: $showLanguagePicker) {
            if let current = currentRecording {
                LanguagePickerView(selectedCode: current.languageCode) { newCode in
                    var updated = current
                    updated.languageCode = newCode
                    store.update(updated)
                }
            }
        }
    }

    private var currentRecording: Recording? {
        store.recordings.first(where: { $0.id == recordingID })
    }

    private func content(for recording: Recording) -> some View {
        VStack(spacing: 16) {
            playerSection(for: recording)
            tabBar
            Divider().background(Theme.cardStroke)
            tabContent(for: recording)
        }
        .padding(.horizontal)
    }

    private func playerSection(for recording: Recording) -> some View {
        VStack(spacing: 10) {
            HStack {
                Text(timeString(player.currentTime))
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Theme.textSecondary)
                    .monospacedDigit()
                Spacer()
                Text(timeString(player.duration == 0 ? recording.duration : player.duration))
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Theme.textSecondary)
                    .monospacedDigit()
            }

            Slider(
                value: Binding(
                    get: { player.currentTime },
                    set: { player.seek(to: $0) }
                ),
                in: 0...(player.duration > 0 ? player.duration : max(recording.duration, 1))
            )
            .tint(Theme.accent)

            Button {
                player.togglePlay()
            } label: {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 48, height: 48)
                    .background(Theme.accent)
                    .clipShape(Circle())
                    .shadow(color: Theme.accent.opacity(0.4), radius: 10, x: 0, y: 4)
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 8)
    }

    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(DetailTab.allCases) { tab in
                    Button {
                        withAnimation(.easeOut(duration: 0.15)) {
                            selectedTab = tab
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: tab.icon)
                                .font(.caption)
                            Text(tab.title)
                                .font(.caption.weight(.semibold))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(selectedTab == tab ? Theme.accent : Theme.pillInactive)
                        .foregroundColor(selectedTab == tab ? .white : Theme.textPrimary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Theme.pillStroke, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
            }
        }
    }

    private func tabContent(for recording: Recording) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(selectedTab.title)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                if selectedTab == .transcription {
                    languageButton(for: recording)
                }
                Button {
                    Task { await regenerate(for: recording) }
                } label: {
                    Image(systemName: isRegenerating ? "hourglass" : "arrow.clockwise")
                        .foregroundColor(Theme.textSecondary)
                        .padding(8)
                }
                .disabled(isRegenerating)
            }

            ScrollView {
                switch selectedTab {
                case .transcription:
                    transcriptionContent(recording.transcription)
                case .summary:
                    summaryContent(recording.summary)
                case .flashCards:
                    FlashCardsPager(cards: recording.flashCards)
                case .bulletPoints:
                    bulletContent(recording.bulletPoints)
                case .quiz:
                    QuizView(questions: recording.quiz)
                }
            }
            .scrollIndicators(.hidden)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 16)
    }

    private func languageButton(for recording: Recording) -> some View {
        Button {
            showLanguagePicker = true
        } label: {
            HStack(spacing: 6) {
                Text(Languages.named(recording.languageCode).flag)
                Text(Languages.named(recording.languageCode).name)
                    .font(.caption.weight(.medium))
                    .foregroundColor(Theme.textPrimary)
                Image(systemName: "chevron.down")
                    .font(.caption2)
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Theme.pillInactive)
            .overlay(Capsule().stroke(Theme.pillStroke, lineWidth: 1))
            .clipShape(Capsule())
        }
    }

    @ViewBuilder
    private func transcriptionContent(_ text: String) -> some View {
        if text.isEmpty {
            EmptyTabState(
                icon: "character.book.closed",
                title: "No transcription yet",
                subtitle: "Tap the refresh icon to transcribe this recording."
            )
        } else {
            Text(text)
                .font(.body)
                .foregroundColor(Theme.textPrimary)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .cardBackground()
        }
    }

    @ViewBuilder
    private func summaryContent(_ text: String) -> some View {
        if text.isEmpty {
            EmptyTabState(
                icon: "doc.text",
                title: "No summary yet",
                subtitle: "Tap the refresh icon to generate a summary."
            )
        } else {
            Text(text)
                .font(.body)
                .foregroundColor(Theme.textPrimary)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .cardBackground()
        }
    }

    @ViewBuilder
    private func bulletContent(_ bullets: [String]) -> some View {
        if bullets.isEmpty {
            EmptyTabState(
                icon: "list.bullet",
                title: "No bullet points yet",
                subtitle: "Tap the refresh icon to generate bullet points."
            )
        } else {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(bullets.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .top, spacing: 10) {
                        Text("•")
                            .foregroundColor(Theme.accent)
                            .font(.headline)
                        Text(item)
                            .foregroundColor(Theme.textPrimary)
                            .font(.subheadline)
                            .lineSpacing(3)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .cardBackground()
        }
    }

    private func loadPlayer() {
        guard let recording = currentRecording else { return }
        let url = StorageService.shared.audioURL(for: recording.audioFileName)
        if FileManager.default.fileExists(atPath: url.path) {
            player.load(url: url)
        }
    }

    private func timeString(_ seconds: TimeInterval) -> String {
        let safe = max(0, seconds)
        let totalSeconds = Int(safe.rounded())
        return String(format: "%02d:%02d", totalSeconds / 60, totalSeconds % 60)
    }

    private func copyContent() {
        guard let rec = currentRecording else { return }
        let text: String
        switch selectedTab {
        case .transcription: text = rec.transcription
        case .summary: text = rec.summary
        case .bulletPoints: text = rec.bulletPoints.map { "• \($0)" }.joined(separator: "\n")
        case .flashCards: text = rec.flashCards.map { "Q: \($0.question)\nA: \($0.answer)" }.joined(separator: "\n\n")
        case .quiz:
            text = rec.quiz.map { question in
                let optionsText = question.options.enumerated().map { idx, opt in
                    "\(idx == question.correctIndex ? "*" : "-") \(opt)"
                }.joined(separator: "\n")
                return "\(question.question)\n\(optionsText)"
            }.joined(separator: "\n\n")
        }
        guard !text.isEmpty else { return }
        UIPasteboard.general.string = text
        withAnimation { showCopyToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation { showCopyToast = false }
        }
    }

    private func regenerate(for recording: Recording) async {
        isRegenerating = true
        defer { isRegenerating = false }
        var updated = recording

        do {
            let url = StorageService.shared.audioURL(for: recording.audioFileName)
            if selectedTab == .transcription || updated.transcription.isEmpty {
                let text = try await TranscriptionService.shared.transcribe(
                    url: url,
                    languageCode: recording.languageCode
                )
                updated.transcription = text
            }
            let analysis = AIService.shared.analyze(transcription: updated.transcription)
            switch selectedTab {
            case .summary: updated.summary = analysis.summary
            case .bulletPoints: updated.bulletPoints = analysis.bulletPoints
            case .flashCards: updated.flashCards = analysis.flashCards
            case .quiz: updated.quiz = analysis.quiz
            case .transcription:
                updated.summary = analysis.summary
                updated.bulletPoints = analysis.bulletPoints
                updated.flashCards = analysis.flashCards
                updated.quiz = analysis.quiz
            }
            store.update(updated)
        } catch {
            print("Regenerate failed: \(error)")
        }
    }
}

struct EmptyTabState: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(Theme.accent)
            Text(title)
                .font(.headline)
                .foregroundColor(Theme.textPrimary)
            Text(subtitle)
                .font(.footnote)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, minHeight: 240)
        .cardBackground()
    }
}
