import Foundation
import Combine

@MainActor
final class DocumentStore: ObservableObject {
    @Published var documents: [PDFDocumentItem] = []
    @Published var searchText: String = ""
    @Published var sortOption: DocumentSortOption = .newest

    private let metadataURL: URL

    static var documentsDirectory: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PDFs", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    init() {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        if !FileManager.default.fileExists(atPath: support.path) {
            try? FileManager.default.createDirectory(at: support, withIntermediateDirectories: true)
        }
        self.metadataURL = support.appendingPathComponent("documents.json")
        load()
    }

    var filteredDocuments: [PDFDocumentItem] {
        let base: [PDFDocumentItem]
        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            base = documents
        } else {
            base = documents.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        switch sortOption {
        case .newest: return base.sorted { $0.createdAt > $1.createdAt }
        case .oldest: return base.sorted { $0.createdAt < $1.createdAt }
        case .nameAZ: return base.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .nameZA: return base.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedDescending }
        case .largest: return base.sorted { $0.fileSize > $1.fileSize }
        case .smallest: return base.sorted { $0.fileSize < $1.fileSize }
        }
    }

    func add(_ doc: PDFDocumentItem) {
        documents.append(doc)
        save()
    }

    func update(_ doc: PDFDocumentItem) {
        guard let idx = documents.firstIndex(where: { $0.id == doc.id }) else { return }
        documents[idx] = doc
        save()
    }

    func delete(_ doc: PDFDocumentItem) {
        try? FileManager.default.removeItem(at: doc.fileURL)
        documents.removeAll { $0.id == doc.id }
        save()
    }

    func rename(_ doc: PDFDocumentItem, to newName: String) {
        var updated = doc
        updated.name = newName
        update(updated)
    }

    func refreshMetadata(for doc: PDFDocumentItem, pageCount: Int) {
        var updated = doc
        updated.pageCount = pageCount
        let attrs = try? FileManager.default.attributesOfItem(atPath: doc.fileURL.path)
        if let size = attrs?[.size] as? Int64 {
            updated.fileSize = size
        }
        update(updated)
    }

    private func load() {
        guard let data = try? Data(contentsOf: metadataURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let loaded = try? decoder.decode([PDFDocumentItem].self, from: data) {
            self.documents = loaded
        }
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(documents) {
            try? data.write(to: metadataURL, options: .atomic)
        }
    }
}
