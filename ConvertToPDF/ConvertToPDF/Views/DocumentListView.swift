import SwiftUI

struct DocumentListView: View {
    @EnvironmentObject var store: DocumentStore
    @State private var showCreateSheet = false
    @State private var showSortSheet = false
    @State private var importError: String?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                VStack(spacing: 16) {
                    searchBar
                        .padding(.horizontal)

                    if store.documents.isEmpty {
                        emptyState
                    } else if store.filteredDocuments.isEmpty {
                        noResultsState
                    } else {
                        documentList
                    }
                }
                .padding(.top, 8)

                floatingActionButton
                    .padding(.trailing, 20)
                    .padding(.bottom, 24)
            }
            .navigationTitle("My Documents")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundColor(Theme.primaryText)
                    }
                }
            }
            .sheet(isPresented: $showCreateSheet) {
                CreatePDFSheet { result in
                    handleImportResult(result)
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .confirmationDialog("Sort documents", isPresented: $showSortSheet, titleVisibility: .visible) {
                ForEach(DocumentSortOption.allCases) { option in
                    Button(option.rawValue) { store.sortOption = option }
                }
                Button("Cancel", role: .cancel) {}
            }
            .alert("Import error", isPresented: .constant(importError != nil)) {
                Button("OK") { importError = nil }
            } message: {
                Text(importError ?? "")
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Theme.secondaryText)
                TextField("Search documents...", text: $store.searchText)
                    .textFieldStyle(.plain)
                if !store.searchText.isEmpty {
                    Button { store.searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Theme.secondaryText)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Theme.surface)
            )

            Button {
                showSortSheet = true
            } label: {
                Image(systemName: "line.3.horizontal.decrease")
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle().fill(Theme.accent)
                    )
            }
        }
    }

    private var documentList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(store.filteredDocuments) { doc in
                    NavigationLink {
                        DocumentDetailView(document: doc)
                    } label: {
                        DocumentRow(document: doc)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            store.delete(doc)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 100)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "doc.richtext")
                .font(.system(size: 64))
                .foregroundColor(Theme.accent.opacity(0.5))
            Text("No documents yet")
                .font(.title3.bold())
            Text("Tap the + button to create your first PDF")
                .font(.subheadline)
                .foregroundColor(Theme.secondaryText)
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var noResultsState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 44))
                .foregroundColor(Theme.secondaryText)
            Text("No matches for \"\(store.searchText)\"")
                .font(.headline)
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var floatingActionButton: some View {
        Button {
            showCreateSheet = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle().fill(Theme.accent)
                        .shadow(color: Theme.accent.opacity(0.35), radius: 10, y: 4)
                )
        }
    }

    private func handleImportResult(_ result: Result<[PDFDocumentItem], Error>) {
        switch result {
        case .success(let docs):
            docs.forEach { store.add($0) }
        case .failure(let error):
            importError = error.localizedDescription
        }
    }
}

struct DocumentRow: View {
    let document: PDFDocumentItem

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Theme.accentSoft)
                    .frame(width: 46, height: 46)
                Text("PDF")
                    .font(.caption.bold())
                    .foregroundColor(Theme.accent)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(document.name)
                        .font(.headline)
                        .foregroundColor(Theme.primaryText)
                        .lineLimit(1)
                    if document.isPasswordProtected {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundColor(Theme.accent)
                    }
                }
                Text(document.subtitle)
                    .font(.subheadline)
                    .foregroundColor(Theme.secondaryText)
                Text(document.formattedDate)
                    .font(.footnote)
                    .foregroundColor(Theme.secondaryText)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundColor(Theme.secondaryText)
        }
        .cardStyle()
    }
}

#Preview {
    DocumentListView()
        .environmentObject(DocumentStore())
}
