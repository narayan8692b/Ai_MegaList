import Foundation
import UIKit

enum StampIdentificationError: Error, LocalizedError {
    case invalidImage
    case networkUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidImage:       return "The image could not be processed."
        case .networkUnavailable: return "Unable to reach the identification service."
        }
    }
}

protocol StampIdentifying {
    func identify(image: UIImage) async throws -> Stamp
}

/// Mock identifier that returns plausible results after a short delay.
/// Swap with a real vision / API-backed implementation in production.
struct MockStampIdentificationService: StampIdentifying {
    func identify(image: UIImage) async throws -> Stamp {
        try await Task.sleep(nanoseconds: 1_400_000_000)

        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw StampIdentificationError.invalidImage
        }

        let candidates: [Stamp] = [Stamp.samplePennyBlack] + Stamp.seedCollection

        // Deterministic-but-varied pick based on image byte count.
        let index = abs(data.count.hashValue) % candidates.count
        var stamp = candidates[index]
        stamp.id = UUID()
        stamp.imageData = data
        stamp.dateAdded = Date()
        // Nudge confidence into a believable 0.78 - 0.97 range.
        let jitter = Double((data.count % 20)) / 100.0
        stamp.aiConfidence = min(0.97, max(0.78, 0.85 + jitter))
        return stamp
    }
}
