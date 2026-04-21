import Foundation

struct PDFDocumentItem: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var fileName: String
    var pageCount: Int
    var fileSize: Int64
    var createdAt: Date
    var isPasswordProtected: Bool

    init(id: UUID = UUID(),
         name: String,
         fileName: String,
         pageCount: Int,
         fileSize: Int64,
         createdAt: Date = Date(),
         isPasswordProtected: Bool = false) {
        self.id = id
        self.name = name
        self.fileName = fileName
        self.pageCount = pageCount
        self.fileSize = fileSize
        self.createdAt = createdAt
        self.isPasswordProtected = isPasswordProtected
    }

    var fileURL: URL {
        DocumentStore.documentsDirectory.appendingPathComponent(fileName)
    }

    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy"
        return formatter.string(from: createdAt)
    }

    var subtitle: String {
        "\(pageCount) pages • \(formattedSize)"
    }
}

enum DocumentSortOption: String, CaseIterable, Identifiable {
    case newest = "Newest first"
    case oldest = "Oldest first"
    case nameAZ = "Name (A–Z)"
    case nameZA = "Name (Z–A)"
    case largest = "Largest first"
    case smallest = "Smallest first"

    var id: String { rawValue }
}
