import Foundation
import UIKit
import Combine

final class DesignStorage: ObservableObject {
    @Published private(set) var designs: [Design] = []

    private let indexURL: URL
    private let imagesDir: URL

    init() {
        let fm = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.indexURL = docs.appendingPathComponent("designs.json")
        self.imagesDir = docs.appendingPathComponent("designs", isDirectory: true)
        if !fm.fileExists(atPath: imagesDir.path) {
            try? fm.createDirectory(at: imagesDir, withIntermediateDirectories: true)
        }
        load()
    }

    func load() {
        guard let data = try? Data(contentsOf: indexURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let decoded = try? decoder.decode([Design].self, from: data) {
            self.designs = decoded.sorted { $0.createdAt > $1.createdAt }
        }
    }

    func save(original: UIImage, generated: UIImage, room: Room, style: DesignStyle, mode: DesignMode, note: String? = nil) -> Design {
        let id = UUID()
        let originalName = "\(id.uuidString)-original.jpg"
        let generatedName = "\(id.uuidString)-generated.jpg"
        writeImage(original, name: originalName)
        writeImage(generated, name: generatedName)
        let design = Design(
            id: id,
            createdAt: Date(),
            roomID: room.id,
            styleID: style.id,
            mode: mode,
            originalImageFilename: originalName,
            generatedImageFilename: generatedName,
            note: note
        )
        designs.insert(design, at: 0)
        persist()
        return design
    }

    func delete(_ design: Design) {
        let fm = FileManager.default
        try? fm.removeItem(at: imageURL(for: design.originalImageFilename))
        try? fm.removeItem(at: imageURL(for: design.generatedImageFilename))
        designs.removeAll { $0.id == design.id }
        persist()
    }

    func image(named filename: String) -> UIImage? {
        UIImage(contentsOfFile: imageURL(for: filename).path)
    }

    private func imageURL(for filename: String) -> URL {
        imagesDir.appendingPathComponent(filename)
    }

    private func writeImage(_ image: UIImage, name: String) {
        guard let data = image.jpegData(compressionQuality: 0.9) else { return }
        try? data.write(to: imageURL(for: name), options: .atomic)
    }

    private func persist() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(designs) {
            try? data.write(to: indexURL, options: .atomic)
        }
    }
}
