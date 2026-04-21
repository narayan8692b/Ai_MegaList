import Foundation
import UIKit

protocol CoinIdentifying {
    func identify(image: UIImage) async throws -> Coin
}

struct MockCoinIdentificationService: CoinIdentifying {
    func identify(image: UIImage) async throws -> Coin {
        try await Task.sleep(nanoseconds: 1_300_000_000)

        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw StampIdentificationError.invalidImage
        }

        let candidates: [Coin] = [Coin.sampleGoldCoin1876] + Coin.seedCollection
        let index = abs(data.count.hashValue) % candidates.count
        var coin = candidates[index]
        coin.id = UUID()
        coin.imageData = data
        coin.dateAdded = Date()

        let jitter = Double((data.count % 25)) / 100.0
        coin.aiConfidence = min(0.97, max(0.68, 0.75 + jitter))
        return coin
    }
}
