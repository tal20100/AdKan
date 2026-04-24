import SwiftUI

struct WeeklySummaryCard: View {
    @EnvironmentObject private var services: ServiceContainer
    @State private var thisWeekMinutes: Int = 0
    @State private var lastWeekMinutes: Int = 0
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
            Text("\(minutes / 60)h \(minutes % 60)m")
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
            Text("\(abs(delta))m")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(improved ? AdKanTheme.successGreen : AdKanTheme.dangerRed)
    }

    private func loadWeeklyData() async {
        let calendar = Calendar.current
        let today = Date()

        var thisWeek = 0
        var lastWeek = 0

        for dayOffset in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) {
                let score = try? await services.scoreSync.fetchWeeklyScore(for: date)
                thisWeek += score ?? 0
            }
            if let date = calendar.date(byAdding: .day, value: -(dayOffset + 7), to: today) {
                let score = try? await services.scoreSync.fetchWeeklyScore(for: date)
                lastWeek += score ?? 0
            }
        }

        thisWeekMinutes = thisWeek
        lastWeekMinutes = lastWeek
        loaded = true
    }
}
