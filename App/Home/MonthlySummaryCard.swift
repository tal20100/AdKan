import SwiftUI

struct MonthlySummaryCard: View {
    @EnvironmentObject private var services: ServiceContainer
    @EnvironmentObject private var languageManager: LanguageManager
    @AppStorage("dailyGoalMinutes") private var goalMinutes: Int = 120
    @State private var dailyAverage: Int?
    @State private var changePercent: Double?
    @State private var loaded = false
    @State private var showSheet = false

    var body: some View {
        PlainCard {
            VStack(spacing: 10) {
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundStyle(AdKanTheme.brandPurple)
                    Text("monthly.card.title")
                        .font(AdKanTheme.cardTitle)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundStyle(.tertiary)
                }

                if loaded {
                    HStack(spacing: 16) {
                        if let avg = dailyAverage {
                            VStack(spacing: 2) {
                                Text(formatMinutes(avg))
                                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                                Text("monthly.dailyAvg")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if let pct = changePercent {
                            VStack(spacing: 2) {
                                HStack(spacing: 4) {
                                    Image(systemName: pct <= 0 ? "arrow.down.right" : "arrow.up.right")
                                        .font(.caption.bold())
                                    Text(String(format: "%.0f%%", abs(pct)))
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                }
                                .foregroundStyle(pct <= 0 ? AdKanTheme.successGreen : AdKanTheme.dangerRed)
                                Text("monthly.vsLastMonth")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()
                    }
                } else {
                    ProgressView()
                        .frame(height: 30)
                }
            }
        }
        .premiumGated(.monthlySummary)
        .contentShape(Rectangle())
        .onTapGesture { showSheet = true }
        .sheet(isPresented: $showSheet) {
            MonthlySummaryView()
        }
        .task { await loadPreview() }
    }

    private func loadPreview() async {
        let builder = MonthlySummaryBuilder(scoreSync: services.scoreSync, goalMinutes: goalMinutes)
        let data = await builder.build(for: Date())
        dailyAverage = data.dailyAverage
        changePercent = data.changePercent
        loaded = true
    }

    private func formatMinutes(_ minutes: Int) -> String {
        TimeFormatter.format(minutes: minutes, locale: languageManager.preferredLanguage)
    }
}
