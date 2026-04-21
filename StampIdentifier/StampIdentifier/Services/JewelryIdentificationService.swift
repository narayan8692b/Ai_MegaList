import Foundation
import UIKit

protocol JewelryIdentifying {
    func identify(image: UIImage) async throws -> Jewelry
}

struct MockJewelryIdentificationService: JewelryIdentifying {
    func identify(image: UIImage) async throws -> Jewelry {
        try await Task.sleep(nanoseconds: 1_300_000_000)

        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw StampIdentificationError.invalidImage
        }

        let candidates: [Jewelry] = [
            Jewelry.sampleSolitaire,
            Jewelry.sampleBaroquePearl
        ] + Jewelry.seedCollection

        let index = abs(data.count.hashValue) % candidates.count
        var piece = candidates[index]
        piece.id = UUID()
        piece.imageData = data
        piece.dateAdded = Date()
        return piece
    }
}

// MARK: eBay fair-price checker

protocol EBayPriceChecking {
    func check(title: String, price: Double) async throws -> EBayListingCheck
}

struct MockEBayPriceCheckingService: EBayPriceChecking {
    func check(title: String, price: Double) async throws -> EBayListingCheck {
        try await Task.sleep(nanoseconds: 900_000_000)

        // Derive a deterministic but varied "market fair price" from the title.
        let seed = abs(title.hashValue) % 100
        let multiplier = 0.90 + Double(seed) / 500.0   // 0.90 - 1.10
        let fair = max(5, price * multiplier)
        let confidence = 0.70 + Double(seed % 30) / 100.0
        return EBayListingCheck(
            listingTitle: title,
            listingPrice: price,
            fairPrice: fair,
            confidence: confidence
        )
    }
}

// MARK: Jewelry AI chat

protocol JewelryAdvising {
    func reply(to prompt: String, about piece: Jewelry, previous: [ChatMessage]) async throws -> String
    func followUpSuggestions(for piece: Jewelry) -> [String]
}

struct MockJewelryAdvisor: JewelryAdvising {
    func reply(to prompt: String, about piece: Jewelry, previous: [ChatMessage]) async throws -> String {
        try await Task.sleep(nanoseconds: 1_000_000_000)

        let lower = prompt.lowercased()
        if lower.contains("value") || lower.contains("worth") || lower.contains("price") {
            return "The estimated value for this piece is \(piece.estimatedValueDisplay), with a typical range of \(Int(piece.valueLow))-\(Int(piece.valueHigh)) USD. \(piece.marketNotes)"
        }
        if lower.contains("care") || lower.contains("clean") {
            return "Clean this piece gently with a soft microfibre cloth. For a gold setting with a pearl or soft stone, avoid ultrasonic cleaners; a drop of pH-neutral soap in lukewarm water and a soft brush will keep it looking its best."
        }
        if lower.contains("real") || lower.contains("authentic") {
            return "Hallmarks on this piece (\(piece.hallmarks.joined(separator: ", "))) are consistent with its stated metal. For firm authentication, a jeweller's acid-test or XRF reading is recommended."
        }
        return "Great question. \(piece.summary)\n\nHere are some follow-up questions you might consider."
    }

    func followUpSuggestions(for piece: Jewelry) -> [String] {
        [
            "What is the best way to care for this \(piece.type.rawValue.lowercased())?",
            "How can I tell if the gemstone is natural?",
            "Where should I sell this for the best price?",
            "Is the hallmark consistent with the stated karat?"
        ]
    }
}
