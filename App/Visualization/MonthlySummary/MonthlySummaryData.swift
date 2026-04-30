import Foundation

struct MonthlySummaryData {
    let month: Date
    let totalMinutes: Int
    let dailyAverage: Int
    let previousMonthTotal: Int?
    let bestDay: DayStat?
    let worstDay: DayStat?
    let daysUnderGoal: Int
    let totalDays: Int
    let dailyBreakdown: [DayStat]

    var changePercent: Double? {
        guard let prev = previousMonthTotal, prev > 0 else { return nil }
        return Double(totalMinutes - prev) / Double(prev) * 100
    }

    var improved: Bool {
        guard let change = changePercent else { return false }
        return change < 0
    }

    struct DayStat: Identifiable {
        let id = UUID()
        let date: Date
        let minutes: Int
    }
}
