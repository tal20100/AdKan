import Foundation

struct MonthlySummaryBuilder {
    let scoreSync: ScoreSyncService
    let goalMinutes: Int

    func build(for month: Date) async -> MonthlySummaryData {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: month) ?? 1..<31
        let totalDays = range.count

        let year = calendar.component(.year, from: month)
        let monthNum = calendar.component(.month, from: month)

        var dailyBreakdown: [MonthlySummaryData.DayStat] = []
        var total = 0

        for day in range {
            guard let date = calendar.date(from: DateComponents(year: year, month: monthNum, day: day)) else { continue }
            if date > Date() { break }
            let minutes = (try? await scoreSync.fetchWeeklyScore(for: date)) ?? 0
            dailyBreakdown.append(.init(date: date, minutes: minutes))
            total += minutes
        }

        let activeDays = max(dailyBreakdown.count, 1)
        let avg = total / activeDays
        let bestDay = dailyBreakdown.min(by: { $0.minutes < $1.minutes })
        let worstDay = dailyBreakdown.max(by: { $0.minutes < $1.minutes })
        let daysUnderGoal = dailyBreakdown.filter { $0.minutes <= goalMinutes && $0.minutes > 0 }.count

        var previousMonthTotal: Int?
        if let prevMonth = calendar.date(byAdding: .month, value: -1, to: month) {
            let prevRange = calendar.range(of: .day, in: .month, for: prevMonth) ?? 1..<31
            let prevYear = calendar.component(.year, from: prevMonth)
            let prevMonthNum = calendar.component(.month, from: prevMonth)
            var prevTotal = 0
            for day in prevRange {
                guard let date = calendar.date(from: DateComponents(year: prevYear, month: prevMonthNum, day: day)) else { continue }
                let minutes = (try? await scoreSync.fetchWeeklyScore(for: date)) ?? 0
                prevTotal += minutes
            }
            if prevTotal > 0 { previousMonthTotal = prevTotal }
        }

        return MonthlySummaryData(
            month: month,
            totalMinutes: total,
            dailyAverage: avg,
            previousMonthTotal: previousMonthTotal,
            bestDay: bestDay,
            worstDay: worstDay,
            daysUnderGoal: daysUnderGoal,
            totalDays: totalDays,
            dailyBreakdown: dailyBreakdown
        )
    }
}
