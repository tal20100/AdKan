import Foundation

final class StreakTracker: ObservableObject {
    @Published private(set) var currentStreak: Int = 0
    @Published private(set) var longestStreak: Int = 0

    private let calendar = Calendar.current
    private let datesKey = "streakGoalMetDates"
    private let longestKey = "streakLongest"

    init() {
        longestStreak = UserDefaults.standard.integer(forKey: longestKey)
        recalculate()
    }

    func recordGoalMet(for date: Date = Date()) {
        var dates = loadDates()
        let day = calendar.startOfDay(for: date)
        if !dates.contains(day) {
            dates.append(day)
            saveDates(dates)
        }
        recalculate()
    }

    private func recalculate() {
        let dates = Set(loadDates().map { calendar.startOfDay(for: $0) })
        var streak = 0
        var day = calendar.startOfDay(for: Date())

        while dates.contains(day) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }

        currentStreak = streak
        if streak > longestStreak {
            longestStreak = streak
            UserDefaults.standard.set(streak, forKey: longestKey)
        }
    }

    private func loadDates() -> [Date] {
        guard let data = UserDefaults.standard.data(forKey: datesKey),
              let dates = try? JSONDecoder().decode([Date].self, from: data)
        else { return [] }
        return dates
    }

    private func saveDates(_ dates: [Date]) {
        if let data = try? JSONEncoder().encode(dates) {
            UserDefaults.standard.set(data, forKey: datesKey)
        }
    }
}
