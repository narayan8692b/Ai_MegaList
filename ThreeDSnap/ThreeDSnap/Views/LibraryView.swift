import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var scanStore: ScanStore
    @State private var query: String = ""

    var filtered: [Scan] {
        guard !query.isEmpty else { return scanStore.scans }
        return scanStore.scans.filter {
            $0.name.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if scanStore.scans.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "tray")
                            .font(.system(size: 56))
                            .foregroundStyle(.white.opacity(0.4))
                        Text("Your scans will appear here")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text("Capture a room from the Scan tab to get started.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filtered) { scan in
                            NavigationLink {
                                ScanDetailView(scan: scan)
                            } label: {
                                ScanRow(scan: scan)
                            }
                            .listRowBackground(Color.clear)
                        }
                        .onDelete { indexSet in
                            let ids = indexSet.map { filtered[$0].id }
                            for id in ids {
                                scanStore.delete(id: id)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Library")
            .searchable(text: $query, prompt: "Search scans")
            .toolbar {
                if !scanStore.scans.isEmpty {
                    EditButton()
                        .tint(.blue)
                }
            }
        }
    }
}

struct ScanRow: View {
    let scan: Scan

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                Image(systemName: "cube.transparent.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 60, height: 60)

            VStack(alignment: .leading, spacing: 4) {
                Text(scan.name)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(scan.summary)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.65))
                Text(scan.createdAt, format: .dateTime.month().day().year().hour().minute())
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.4))
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    LibraryView()
        .environmentObject(ScanStore.preview)
}
