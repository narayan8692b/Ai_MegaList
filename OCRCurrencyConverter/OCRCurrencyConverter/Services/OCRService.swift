import Foundation
import Vision

final class OCRService {

    // Prioritise "X.XX" or "X,XX" price-like tokens; fall back to bare integers.
    private static let priceRegexes: [NSRegularExpression] = [
        try! NSRegularExpression(pattern: #"(\d{1,6}[.,]\d{2})"#),
        try! NSRegularExpression(pattern: #"(\d{1,6})"#),
    ]

    func detectPrice(in pixelBuffer: CVPixelBuffer,
                     completion: @escaping (Double?) -> Void) {
        let request = VNRecognizeTextRequest { [weak self] req, _ in
            let strings = (req.results as? [VNRecognizedTextObservation] ?? [])
                .compactMap { $0.topCandidates(1).first?.string }
            let price = self?.bestPrice(from: strings)
            DispatchQueue.main.async { completion(price) }
        }
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }

    // MARK: - Private

    private func bestPrice(from strings: [String]) -> Double? {
        var candidates: [Double] = []

        for string in strings {
            for regex in Self.priceRegexes {
                let ns = string as NSString
                let matches = regex.matches(in: string, range: NSRange(location: 0, length: ns.length))
                for match in matches {
                    guard let range = Range(match.range(at: 1), in: string) else { continue }
                    var token = String(string[range]).replacingOccurrences(of: ",", with: ".")
                    if let value = Double(token), (0.01...99_999).contains(value) {
                        candidates.append(value)
                    }
                }
                if !candidates.isEmpty { break }
            }
        }

        // Prefer prices that look like retail amounts (have decimals, < 10000)
        if let retail = candidates.first(where: { $0.truncatingRemainder(dividingBy: 1) != 0 && $0 < 10_000 }) {
            return retail
        }
        return candidates.first
    }
}
