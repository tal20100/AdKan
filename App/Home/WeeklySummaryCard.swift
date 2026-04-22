import SwiftUI

struct WeeklySummaryCard: View {
    @AppStorage("dailyGoalMinutes") private var goalMinutes: Int = 120

    // TODO: Replace with real weekly data from ScoreSyncService
    private let thisWeekMinutes: Int = 680
    private let lastWeekMinutes: Int = 820

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

                HStack(spacing: 20) {
                    weekColumn(titleKey: "home.thisWeek", minutes: thisWeekMinutes)

                    Divider()
                        .frame(height: 40)

                    weekColumn(titleKey: "home.lastWeek", minutes: lastWeekMinutes)

                    Spacer()

                    deltaView
                }
            }
        }
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
}
