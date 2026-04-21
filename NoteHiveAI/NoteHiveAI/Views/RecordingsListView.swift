import SwiftUI

struct RecordingsListView: View {
    @EnvironmentObject var store: RecordingsStore
    @State private var showRecorder = false
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                VStack(spacing: 16) {
                    searchBar
                    if store.filteredRecordings.isEmpty {
                        emptyState
                    } else {
                        recordingsList
                    }
                }
                .padding(.horizontal)

                floatingAddButton
            }
            .navigationTitle("NoteHive AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                            .foregroundColor(Theme.textPrimary)
                    }
                }
            }
            .sheet(isPresented: $showRecorder) {
                RecorderSheet()
                    .environmentObject(store)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
        .tint(Theme.accent)
    }

    private var searchBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Theme.textTertiary)
                TextField("Search recordings...", text: $store.searchText)
                    .foregroundColor(Theme.textPrimary)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .cardBackground()

            Button {
                store.sortNewestFirst.toggle()
            } label: {
                Image(systemName: store.sortNewestFirst
                      ? "line.3.horizontal.decrease"
                      : "line.3.horizontal.decrease.circle")
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Theme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(.top, 8)
    }

    private var recordingsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(store.filteredRecordings) { recording in
                    NavigationLink(value: recording) {
                        RecordingRow(recording: recording)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 100)
        }
        .scrollIndicators(.hidden)
        .navigationDestination(for: Recording.self) { recording in
            RecordingDetailView(recordingID: recording.id)
                .environmentObject(store)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "mic.circle")
                .font(.system(size: 72))
                .foregroundColor(Theme.accent)
            Text("No recordings yet")
                .font(.title3.weight(.semibold))
                .foregroundColor(Theme.textPrimary)
            Text("Tap the + button below to capture your first note.")
                .font(.footnote)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }

    private var floatingAddButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button {
                    showRecorder = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title2.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Theme.accent)
                        .clipShape(Circle())
                        .shadow(color: Theme.accent.opacity(0.45), radius: 14, x: 0, y: 6)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 24)
            }
        }
    }
}

private struct RecordingRow: View {
    let recording: Recording

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Theme.accent)
                        .frame(width: 36, height: 36)
                    Image(systemName: "mic.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 15, weight: .semibold))
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(recording.title)
                        .font(.headline)
                        .foregroundColor(Theme.textPrimary)
                        .lineLimit(1)
                    Text(recording.formattedCreatedAt)
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }
                Spacer()
                Text(recording.formattedDuration)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Theme.durationBadge)
                    .clipShape(Capsule())
            }
            Text(recording.preview)
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)

            HStack(spacing: 6) {
                TagPill(icon: "character.book.closed", title: "Transcription")
                TagPill(icon: "doc.text", title: "Summary")
                TagPill(icon: "rectangle.on.rectangle", title: "Flash Cards")
                TagPill(icon: "list.bullet", title: "Bullet Points")
                TagPill(icon: "questionmark.circle", title: "Quiz")
            }
        }
        .padding(14)
        .cardBackground()
    }
}

private struct TagPill: View {
    let icon: String
    let title: String
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(title)
                .font(.caption2)
                .lineLimit(1)
        }
        .foregroundColor(Theme.textSecondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Theme.pillInactive)
        .overlay(
            Capsule().stroke(Theme.pillStroke, lineWidth: 1)
        )
        .clipShape(Capsule())
    }
}
