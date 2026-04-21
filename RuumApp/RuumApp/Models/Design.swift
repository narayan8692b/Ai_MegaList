import Foundation
import UIKit

struct Design: Identifiable, Codable, Hashable {
    let id: UUID
    let createdAt: Date
    let roomID: String
    let styleID: String
    let mode: DesignMode
    let originalImageFilename: String
    let generatedImageFilename: String
    var note: String?

    var room: Room { Room.all.first { $0.id == roomID } ?? Room.all[0] }
    var style: DesignStyle { DesignStyle.all.first { $0.id == styleID } ?? DesignStyle.all[0] }
}
