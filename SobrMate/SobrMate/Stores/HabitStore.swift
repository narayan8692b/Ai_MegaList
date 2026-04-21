import Foundation
import Combine

final class HabitStore: ObservableObject {
    @Published var habits: [Habit] = []
    @Published private(set) var tick: Date = Date()

    private let storageKey = "sobrmate.habits.v1"
    private var timer: AnyCancellable?

    init() {
        load()
        if habits.isEmpty {
            habits = Habit.samples
            save()
        }
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] date in self?.tick = date }
    }

    func add(_ habit: Habit) {
        habits.append(habit)
        save()
    }

    func update(_ habit: Habit) {
        guard let idx = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        habits[idx] = habit
        save()
    }

    func delete(_ habit: Habit) {
        habits.removeAll { $0.id == habit.id }
        save()
    }

    func logRelapse(for habit: Habit, on date: Date = Date()) {
        guard let idx = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        habits[idx].relapses.append(date)
        save()
    }

    func resetStreak(for habit: Habit) {
        guard let idx = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        habits[idx].relapses.append(Date())
        save()
    }

    var totalHabits: Int { habits.count }

    var averageStreak: Double {
        guard !habits.isEmpty else { return 0 }
        let total = habits.reduce(0) { $0 + $1.currentStreakDays }
        return Double(total) / Double(habits.count)
    }

    var bestCurrentStreak: Int {
        habits.map(\.currentStreakDays).max() ?? 0
    }

    private func save() {
        if let data = try? JSONEncoder().encode(habits) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([Habit].self, from: data) else { return }
        habits = decoded
    }
}
