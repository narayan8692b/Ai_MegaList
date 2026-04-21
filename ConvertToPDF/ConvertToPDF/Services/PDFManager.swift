import Foundation
import PDFKit
import UIKit

enum PDFManagerError: Error, LocalizedError {
    case emptyInput
    case writeFailed
    case invalidPDF
    case downloadFailed(String)

    var errorDescription: String? {
        switch self {
        case .emptyInput: return "No pages were provided."
        case .writeFailed: return "Failed to write the PDF file."
        case .invalidPDF: return "The file is not a valid PDF."
        case .downloadFailed(let msg): return "Download failed: \(msg)"
        }
    }
}

enum PDFManager {
    static func makePDF(from images: [UIImage], named name: String) throws -> PDFDocumentItem {
        guard !images.isEmpty else { throw PDFManagerError.emptyInput }

        let pageSize = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter @ 72dpi
        let renderer = UIGraphicsPDFRenderer(bounds: pageSize)
        let data = renderer.pdfData { ctx in
            for image in images {
                ctx.beginPage()
                let rect = aspectFitRect(for: image.size, in: pageSize.insetBy(dx: 24, dy: 24))
                image.draw(in: rect)
            }
        }

        let fileName = "\(UUID().uuidString).pdf"
        let url = DocumentStore.documentsDirectory.appendingPathComponent(fileName)
        do { try data.write(to: url, options: .atomic) }
        catch { throw PDFManagerError.writeFailed }

        let size = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? Int64(data.count)
        return PDFDocumentItem(
            name: name,
            fileName: fileName,
            pageCount: images.count,
            fileSize: size
        )
    }

    static func importPDF(from sourceURL: URL, preferredName: String? = nil) throws -> PDFDocumentItem {
        let needsStop = sourceURL.startAccessingSecurityScopedResource()
        defer { if needsStop { sourceURL.stopAccessingSecurityScopedResource() } }

        guard let pdf = PDFDocument(url: sourceURL) else { throw PDFManagerError.invalidPDF }
        let fileName = "\(UUID().uuidString).pdf"
        let destURL = DocumentStore.documentsDirectory.appendingPathComponent(fileName)
        guard pdf.write(to: destURL) else { throw PDFManagerError.writeFailed }

        let size = (try? FileManager.default.attributesOfItem(atPath: destURL.path)[.size] as? Int64) ?? 0
        let name = preferredName ?? sourceURL.deletingPathExtension().lastPathComponent
        return PDFDocumentItem(
            name: name,
            fileName: fileName,
            pageCount: pdf.pageCount,
            fileSize: size,
            isPasswordProtected: pdf.isEncrypted
        )
    }

    static func downloadPDF(from url: URL) async throws -> PDFDocumentItem {
        let (tempURL, response) = try await URLSession.shared.download(from: url)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw PDFManagerError.downloadFailed("HTTP \(http.statusCode)")
        }
        let fileName = "\(UUID().uuidString).pdf"
        let destURL = DocumentStore.documentsDirectory.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: destURL)
        try FileManager.default.moveItem(at: tempURL, to: destURL)

        guard let pdf = PDFDocument(url: destURL) else {
            try? FileManager.default.removeItem(at: destURL)
            throw PDFManagerError.invalidPDF
        }
        let size = (try? FileManager.default.attributesOfItem(atPath: destURL.path)[.size] as? Int64) ?? 0
        let name = url.deletingPathExtension().lastPathComponent.isEmpty
            ? "Downloaded \(Date().formatted(date: .abbreviated, time: .omitted))"
            : url.deletingPathExtension().lastPathComponent
        return PDFDocumentItem(
            name: name,
            fileName: fileName,
            pageCount: pdf.pageCount,
            fileSize: size,
            isPasswordProtected: pdf.isEncrypted
        )
    }

    static func rewrite(_ doc: PDFDocumentItem, keeping pageIndexes: [Int]) throws -> (pageCount: Int, size: Int64) {
        guard let source = PDFDocument(url: doc.fileURL) else { throw PDFManagerError.invalidPDF }
        let output = PDFDocument()
        var outputIndex = 0
        for index in pageIndexes {
            guard let page = source.page(at: index) else { continue }
            output.insert(page, at: outputIndex)
            outputIndex += 1
        }
        guard output.pageCount > 0 else { throw PDFManagerError.emptyInput }
        guard output.write(to: doc.fileURL) else { throw PDFManagerError.writeFailed }
        let size = (try? FileManager.default.attributesOfItem(atPath: doc.fileURL.path)[.size] as? Int64) ?? 0
        return (output.pageCount, size)
    }

    static func appendImagesAsPages(to doc: PDFDocumentItem, images: [UIImage]) throws -> (pageCount: Int, size: Int64) {
        guard let source = PDFDocument(url: doc.fileURL) else { throw PDFManagerError.invalidPDF }
        let pageSize = CGRect(x: 0, y: 0, width: 612, height: 792)
        for image in images {
            let renderer = UIGraphicsPDFRenderer(bounds: pageSize)
            let data = renderer.pdfData { ctx in
                ctx.beginPage()
                let rect = aspectFitRect(for: image.size, in: pageSize.insetBy(dx: 24, dy: 24))
                image.draw(in: rect)
            }
            guard let tempDoc = PDFDocument(data: data), let page = tempDoc.page(at: 0) else { continue }
            source.insert(page, at: source.pageCount)
        }
        guard source.write(to: doc.fileURL) else { throw PDFManagerError.writeFailed }
        let size = (try? FileManager.default.attributesOfItem(atPath: doc.fileURL.path)[.size] as? Int64) ?? 0
        return (source.pageCount, size)
    }

    static func setPassword(_ password: String, on doc: PDFDocumentItem) throws {
        guard let source = PDFDocument(url: doc.fileURL) else { throw PDFManagerError.invalidPDF }
        let options: [PDFDocumentWriteOption: Any] = [
            .userPasswordOption: password,
            .ownerPasswordOption: password
        ]
        guard source.write(to: doc.fileURL, withOptions: options) else { throw PDFManagerError.writeFailed }
    }

    static func removePassword(from doc: PDFDocumentItem, password: String) throws {
        guard let source = PDFDocument(url: doc.fileURL) else { throw PDFManagerError.invalidPDF }
        if source.isLocked {
            guard source.unlock(withPassword: password) else { throw PDFManagerError.invalidPDF }
        }
        guard source.write(to: doc.fileURL) else { throw PDFManagerError.writeFailed }
    }

    static func thumbnail(for url: URL, pageIndex: Int, size: CGSize) -> UIImage? {
        guard let doc = PDFDocument(url: url), let page = doc.page(at: pageIndex) else { return nil }
        return page.thumbnail(of: size, for: .cropBox)
    }

    private static func aspectFitRect(for imageSize: CGSize, in bounds: CGRect) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else { return bounds }
        let scale = min(bounds.width / imageSize.width, bounds.height / imageSize.height)
        let width = imageSize.width * scale
        let height = imageSize.height * scale
        let x = bounds.origin.x + (bounds.width - width) / 2
        let y = bounds.origin.y + (bounds.height - height) / 2
        return CGRect(x: x, y: y, width: width, height: height)
    }
}
