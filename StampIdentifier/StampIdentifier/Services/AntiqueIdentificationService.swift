import Foundation
import UIKit

protocol AntiqueIdentifying {
    func identify(image: UIImage) async throws -> Antique
}

struct MockAntiqueIdentificationService: AntiqueIdentifying {
    func identify(image: UIImage) async throws -> Antique {
        try await Task.sleep(nanoseconds: 1_400_000_000)

        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw StampIdentificationError.invalidImage
        }

        let candidates: [Antique] = [Antique.sampleBronzeVase] + Antique.seedCollection
        let index = abs(data.count.hashValue) % candidates.count
        var antique = candidates[index]
        antique.id = UUID()
        antique.imageData = data
        antique.dateAdded = Date()

        let jitter = Double((data.count % 22)) / 100.0
        antique.aiConfidence = min(0.96, max(0.70, 0.75 + jitter))
        return antique
    }
}
