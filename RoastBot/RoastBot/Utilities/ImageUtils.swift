import UIKit

extension UIImage {
    /// Resize to max 1024px on the longest side — keeps API costs low.
    func resizedForAPI(maxDimension: CGFloat = 1024) -> UIImage? {
        let longest = max(size.width, size.height)
        guard longest > maxDimension else { return self }

        let scale = maxDimension / longest
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
