import SwiftUI
import PDFKit
import PhotosUI

struct PageEntry: Identifiable, Equatable {
    let id = UUID()
    let originalIndex: Int
    let thumbnail: UIImage?
}

struct ManagePagesView: View {
    @EnvironmentObject var store: DocumentStore
    @Environment(\.dismiss) private var dismiss

    @Binding var document: PDFDocumentItem
    var onSave: () -> Void

    @State private var entries: [PageEntry] = []
    @State private var selection: Set<UUID> = []
    @State private var isLoading = true
    @State private var showAddSheet = false
    @State private var showPhotosPicker = false
    @State private var photoSelections: [PhotosPickerItem] = []
    @State private var pendingImages: [UIImage] = []
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            headerBar

            if isLoading {
                Spacer()
                ProgressView("Loading pages…")
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(Array(entries.enumerated()), id: \.element.id) { idx, entry in
                            pageRow(index: idx, entry: entry)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 120)
                }
            }

            bottomBar
        }
        .navigationTitle("Manage Pages")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                        toggleSelectAll()
                    } label: {
                        Image(systemName: selection.count == entries.count && !entries.isEmpty
                              ? "checkmark.square.fill"
                              : "square")
                            .foregroundColor(Theme.accent)
                    }
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(Theme.accent)
                    }
                }
            }
        }
        .task { await loadPages() }
        .confirmationDialog("Add pages", isPresented: $showAddSheet, titleVisibility: .visible) {
            Button("From Gallery") { showPhotosPicker = true }
            Button("Cancel", role: .cancel) {}
        }
        .photosPicker(
            isPresented: $showPhotosPicker,
            selection: $photoSelections,
            maxSelectionCount: 0,
            matching: .images
        )
        .onChange(of: photoSelections) { _, items in
            guard !items.isEmpty else { return }
            Task {
                var imgs: [UIImage] = []
                for item in items {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let img = UIImage(data: data) {
                        imgs.append(img)
                    }
                }
                pendingImages = imgs
                photoSelections = []
            }
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .overlay {
            if isSaving {
                ProgressView("Saving…")
                    .padding(24)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    private var headerBar: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("\(entries.count) page\(entries.count == 1 ? "" : "s")")
                    .font(.headline)
                Spacer()
                if !selection.isEmpty {
                    Button(role: .destructive) {
                        deleteSelected()
                    } label: {
                        Label("Delete (\(selection.count))", systemImage: "trash")
                            .labelStyle(.titleAndIcon)
                    }
                    .foregroundColor(.red)
                }
            }
            Text("Long press and drag to reorder • Tap checkbox to select")
                .font(.caption)
                .foregroundColor(Theme.secondaryText)
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private func pageRow(index: Int, entry: PageEntry) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Theme.surface)
                    .frame(width: 60, height: 72)
                if let thumb = entry.thumbnail {
                    Image(uiImage: thumb)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 58, height: 70)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                } else {
                    Image(systemName: "doc.text")
                        .foregroundColor(Theme.secondaryText)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Page \(index + 1)")
                    .font(.headline)
                Text("Tap to select")
                    .font(.subheadline)
                    .foregroundColor(Theme.secondaryText)
            }
            Spacer()
            Button {
                toggle(entry)
            } label: {
                Image(systemName: selection.contains(entry.id) ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundColor(selection.contains(entry.id) ? Theme.accent : Theme.secondaryText)
            }
            .buttonStyle(.plain)

            Image(systemName: "line.3.horizontal")
                .foregroundColor(Theme.secondaryText)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.background)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Theme.cardBorder, lineWidth: 1)
                )
        )
        .onDrag {
            NSItemProvider(object: entry.id.uuidString as NSString)
        }
        .onDrop(of: [.text], delegate: PageDropDelegate(targetId: entry.id, entries: $entries))
    }

    private var bottomBar: some View {
        VStack {
            Button {
                save()
            } label: {
                Text("Save Changes")
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
        .background(
            Theme.background
                .ignoresSafeArea(edges: .bottom)
                .shadow(color: .black.opacity(0.05), radius: 8, y: -4)
        )
    }

    private func loadPages() async {
        isLoading = true
        defer { isLoading = false }
        guard let pdf = PDFDocument(url: document.fileURL) else { return }
        var loaded: [PageEntry] = []
        for i in 0..<pdf.pageCount {
            let thumb = pdf.page(at: i)?.thumbnail(of: CGSize(width: 120, height: 160), for: .cropBox)
            loaded.append(PageEntry(originalIndex: i, thumbnail: thumb))
        }
        self.entries = loaded
    }

    private func toggle(_ entry: PageEntry) {
        if selection.contains(entry.id) { selection.remove(entry.id) }
        else { selection.insert(entry.id) }
    }

    private func toggleSelectAll() {
        if selection.count == entries.count {
            selection.removeAll()
        } else {
            selection = Set(entries.map { $0.id })
        }
    }

    private func deleteSelected() {
        guard !selection.isEmpty else { return }
        entries.removeAll { selection.contains($0.id) }
        selection.removeAll()
    }

    private func save() {
        Task {
            isSaving = true
            defer { isSaving = false }
            do {
                let indexes = entries.map { $0.originalIndex }
                let result = try PDFManager.rewrite(document, keeping: indexes)
                document.pageCount = result.pageCount
                document.fileSize = result.size
                if !pendingImages.isEmpty {
                    let appendResult = try PDFManager.appendImagesAsPages(to: document, images: pendingImages)
                    document.pageCount = appendResult.pageCount
                    document.fileSize = appendResult.size
                    pendingImages = []
                }
                store.update(document)
                onSave()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

struct PageDropDelegate: DropDelegate {
    let targetId: UUID
    @Binding var entries: [PageEntry]

    func performDrop(info: DropInfo) -> Bool { true }

    func dropEntered(info: DropInfo) {
        guard let provider = info.itemProviders(for: [.text]).first else { return }
        provider.loadObject(ofClass: NSString.self) { value, _ in
            DispatchQueue.main.async {
                guard let str = value as? String,
                      let draggedId = UUID(uuidString: str),
                      draggedId != targetId,
                      let from = entries.firstIndex(where: { $0.id == draggedId }),
                      let to = entries.firstIndex(where: { $0.id == targetId })
                else { return }
                if from != to {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        entries.move(fromOffsets: IndexSet(integer: from),
                                     toOffset: to > from ? to + 1 : to)
                    }
                }
            }
        }
    }
}
