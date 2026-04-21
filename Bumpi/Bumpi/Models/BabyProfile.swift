import Foundation
import SwiftUI

struct BabyProfile: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var dueDate: Date
    var createdAt: Date

    init(id: UUID = UUID(), name: String, dueDate: Date, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.dueDate = dueDate
        self.createdAt = createdAt
    }
}

@MainActor
final class BabyProfileStore: ObservableObject {
    @Published private(set) var profile: BabyProfile?

    private let storageKey = "bumpi.baby.profile.v1"

    init() {
        load()
    }

    func save(_ profile: BabyProfile) {
        self.profile = profile
        persist()
    }

    func update(name: String? = nil, dueDate: Date? = nil) {
        guard var current = profile else { return }
        if let name { current.name = name }
        if let dueDate { current.dueDate = dueDate }
        self.profile = current
        persist()
    }

    func clear() {
        profile = nil
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    private func persist() {
        guard let profile else { return }
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode(BabyProfile.self, from: data) else { return }
        profile = decoded
    }
}

struct DueDateCountdown {
    let days: Int
    let hours: Int
    let minutes: Int
    let isPast: Bool

    static func from(dueDate: Date, now: Date = Date()) -> DueDateCountdown {
        let interval = dueDate.timeIntervalSince(now)
        let isPast = interval < 0
        let absInterval = abs(interval)
        let totalMinutes = Int(absInterval / 60)
        let days = totalMinutes / (60 * 24)
        let hours = (totalMinutes / 60) % 24
        let minutes = totalMinutes % 60
        return DueDateCountdown(days: days, hours: hours, minutes: minutes, isPast: isPast)
    }
}
