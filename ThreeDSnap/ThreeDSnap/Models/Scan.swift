import Foundation
import CoreGraphics

struct Scan: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var createdAt: Date
    var rooms: [Room]
    var lengthUnit: LengthUnit

    init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = Date(),
        rooms: [Room],
        lengthUnit: LengthUnit = .feet
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.rooms = rooms
        self.lengthUnit = lengthUnit
    }

    var totalAreaSquareMeters: Double {
        rooms.reduce(0) { $0 + $1.areaSquareMeters }
    }

    var boundingSizeMeters: CGSize {
        guard let first = rooms.first else { return .zero }
        var minX = Double.greatestFiniteMagnitude
        var minY = Double.greatestFiniteMagnitude
        var maxX = -Double.greatestFiniteMagnitude
        var maxY = -Double.greatestFiniteMagnitude

        for room in rooms {
            minX = min(minX, room.origin.x)
            minY = min(minY, room.origin.y)
            maxX = max(maxX, room.origin.x + room.size.width)
            maxY = max(maxY, room.origin.y + room.size.height)
        }
        if minX == .greatestFiniteMagnitude {
            return CGSize(width: first.size.width, height: first.size.height)
        }
        return CGSize(width: maxX - minX, height: maxY - minY)
    }

    var summary: String {
        let area = MeasurementFormatter.formatArea(totalAreaSquareMeters, unit: lengthUnit)
        return "\(rooms.count) room\(rooms.count == 1 ? "" : "s") · \(area)"
    }
}

struct Room: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var origin: CGPoint
    var size: CGSize
    var doors: [Opening]
    var windows: [Opening]

    init(
        id: UUID = UUID(),
        name: String,
        origin: CGPoint,
        size: CGSize,
        doors: [Opening] = [],
        windows: [Opening] = []
    ) {
        self.id = id
        self.name = name
        self.origin = origin
        self.size = size
        self.doors = doors
        self.windows = windows
    }

    var areaSquareMeters: Double {
        Double(size.width * size.height)
    }
}

struct Opening: Identifiable, Codable, Hashable {
    enum Wall: String, Codable, Hashable { case top, bottom, leading, trailing }
    var id: UUID = UUID()
    var wall: Wall
    var offset: Double
    var width: Double
}

enum LengthUnit: String, Codable, CaseIterable {
    case meters
    case feet

    var label: String {
        switch self {
        case .meters: return "Metric (m)"
        case .feet: return "Imperial (ft)"
        }
    }
}

enum MeasurementFormatter {
    static let areaFormatter: Foundation.MeasurementFormatter = makeFormatter()
    static let lengthFormatter: Foundation.MeasurementFormatter = makeFormatter()

    private static func makeFormatter() -> Foundation.MeasurementFormatter {
        let f = Foundation.MeasurementFormatter()
        f.unitStyle = .medium
        f.unitOptions = [.providedUnit]
        f.numberFormatter.maximumFractionDigits = 2
        f.numberFormatter.minimumFractionDigits = 2
        return f
    }

    static func formatLength(_ meters: Double, unit: LengthUnit) -> String {
        let m = Measurement(value: meters, unit: UnitLength.meters)
        let converted: Measurement<UnitLength>
        switch unit {
        case .meters: converted = m
        case .feet: converted = m.converted(to: .feet)
        }
        return lengthFormatter.string(from: converted)
    }

    static func formatArea(_ squareMeters: Double, unit: LengthUnit) -> String {
        let m = Measurement(value: squareMeters, unit: UnitArea.squareMeters)
        let converted: Measurement<UnitArea>
        switch unit {
        case .meters: converted = m
        case .feet: converted = m.converted(to: .squareFeet)
        }
        return areaFormatter.string(from: converted)
    }
}
