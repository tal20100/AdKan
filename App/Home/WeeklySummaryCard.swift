import SwiftUI

struct WeeklySummaryCard: View {
    @EnvironmentObject private var services: ServiceContainer
    @EnvironmentObject private var languageManager: LanguageManager
    @AppStorage("dailyGoalMinutes") private var goalMinutes: Int = 120
    @State private var thisWeekMinutes: Int = 0
    @State private var lastWeekMinutes: Int = 0
    @State private var dailyMinutes: [Int] = []
    @State private var loaded = false

    private var delta: Int { thisWeekMinutes - lastWeekMinutes }
    private var improved: Bool { delta <= 0 }

    var body: some View {
        PlainCard {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundStyle(AdKanTheme.primary)
                    Text("home.weeklySummary")
                        .font(AdKanTheme.cardTitle)
                    Spacer()
                }

                if loaded {
                    if !dailyMinutes.isEmpty {
                        sparkline
                    }

                    HStack(spacing: 20) {
                        weekColumn(titleKey: "home.thisWeek", minutes: thisWeekMinutes)

                        Divider()
                            .frame(height: 40)

                        weekColumn(titleKey: "home.lastWeek", minutes: lastWeekMinutes)

                        Spacer()

                        deltaView
                    }
                } else {
                    ProgressView()
                        .frame(height: 40)
                }
            }
        }
        .task { await loadWeeklyData() }
    }

    private func weekColumn(titleKey: String, minutes: Int) -> some View {
        VStack(spacing: 4) {
            Text(TimeFormatter.format(minutes: minutes, locale: languageManager.preferredLanguage))
                .font(.system(size: 18, weight: .semibold, design: .rounded))
            Text(LocalizedStringKey(titleKey))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var deltaView: some View {
        VStack(spacing: 2) {
            Image(systemName: improved ? "arrow.down.right" : "arrow.up.right")
                .font(.caption.bold())
            Text(TimeFormatter.format(minutes: abs(delta), locale: languageManager.preferredLanguage))
                .font(.system(size: 14, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(improved ? AdKanTheme.successGreen : AdKanTheme.dangerRed)
    }

    private var sparkline: some View {
        HStack(spacing: 6) {
            ForEach(Array(dailyMinutes.enumerated()), id: \.offset) { _, minutes in
                Circle()
                    .fill(minutes <= goalMinutes ? AdKanTheme.brandGreen : AdKanTheme.surfaceGray)
                    .frame(width: 10, height: 10)
            }
        }
    }

    private func loadWeeklyData() async {
        let calendar = Calendar.current
        let today = Date()

        var thisWeek = 0
        var lastWeek = 0
        var daily: [Int] = []

        for dayOffset in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -(6 - dayOffset), to: today) {
                let score = (try? await services.scoreSync.fetchWeeklyScore(for: date))
                    ?? LocalScoreStore.load(for: date)
                    ?? 0
                thisWeek += score
                daily.append(score)
            }
            if let date = calendar.date(byAdding: .day, value: -(dayOffset + 7), to: today) {
                let score = (try? await services.scoreSync.fetchWeeklyScore(for: date))
                    ?? LocalScoreStore.load(for: date)
                    ?? 0
                lastWeek += score
            }
        }

        thisWeekMinutes = thisWeek
        lastWeekMinutes = lastWeek
        dailyMinutes = daily
        loaded = true
    }
}
