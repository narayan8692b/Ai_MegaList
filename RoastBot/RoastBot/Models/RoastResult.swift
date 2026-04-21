import Foundation
import UIKit

struct RoastResult: Identifiable {
    let id = UUID()
    let text: String
    let style: RoastStyle
    let intensity: Int
    let image: UIImage
    let createdAt: Date = .now
}
