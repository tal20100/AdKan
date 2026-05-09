import SwiftUI
import Charts

struct MonthlySummaryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var services: ServiceContainer
    @EnvironmentObject private var languageManager: LanguageManager
    @AppStorage("dailyGoalMinutes") private var goalMinutes: Int = 120
    @State private var data: MonthlySummaryData?
    @State private var isLoading = true

    private var monthFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f
    }

    private var dayFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 400)
                } else if let data {
                    content(data)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(Text("monthly.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .task { await loadData() }
    }

    @ViewBuilder
    private func content(_ data: MonthlySummaryData) -> some View {
        VStack(spacing: AdKanTheme.cardSpacing) {
            heroCard(data)
            if data.changePercent != nil {
                comparisonCard(data)
            }
            chartCard(data)
            highlightsCard(data)
            encouragementCard(data)
        }
        .padding(.horizontal, AdKanTheme.screenPadding)
        .padding(.vertical, 16)
    }

    private func heroCard(_ data: MonthlySummaryData) -> some View {
        GradientCard(gradient: AdKanTheme.premiumGradient) {
            VStack(spacing: 12) {
                Text(monthFormatter.string(from: data.month))
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.8))

                Text(formatHours(data.totalMinutes))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("monthly.totalTime")
                    .font(AdKanTheme.heroLabel)
                    .foregroundStyle(.white.opacity(0.7))

                Divider()
                    .background(.white.opacity(0.3))
                    .padding(.horizontal, 20)

                HStack(spacing: 32) {
                    VStack(spacing: 4) {
                        Text(formatMinutes(data.dailyAverage))
                            .font(.title3.bold())
                            .foregroundStyle(.white)
                        Text("monthly.dailyAvg")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }

                    VStack(spacing: 4) {
                        Text("\(data.daysUnderGoal)/\(data.dailyBreakdown.count)")
                            .font(.title3.bold())
                            .foregroundStyle(.white)
                        Text("monthly.daysUnderGoal")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
        }
    }

    private func comparisonCard(_ data: MonthlySummaryData) -> some View {
        PlainCard {
            HStack(spacing: 16) {
                Image(systemName: data.improved ? "arrow.down.right.circle.fill" : "arrow.up.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(data.improved ? AdKanTheme.successGreen : AdKanTheme.dangerRed)

                VStack(alignment: .leading, spacing: 2) {
                    Text("monthly.vsLastMonth")
                        .font(AdKanTheme.cardBody)
                        .foregroundStyle(.secondary)

                    if let pct = data.changePercent {
                        Text(String(format: "%+.0f%%", pct))
                            .font(.title3.bold())
                            .foregroundStyle(data.improved ? AdKanTheme.successGreen : AdKanTheme.dangerRed)
                    }
                }

                Spacer()

                if let prev = data.previousMonthTotal {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("monthly.lastMonth")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(formatHours(prev))
                            .font(.subheadline.weight(.semibold))
                    }
                }
            }
        }
    }

    private func chartCard(_ data: MonthlySummaryData) -> some View {
        PlainCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundStyle(AdKanTheme.primary)
                    Text("monthly.dailyChart")
                        .font(AdKanTheme.cardTitle)
                    Spacer()
                }

                if !data.dailyBreakdown.isEmpty {
                    Chart(data.dailyBreakdown) { day in
                        BarMark(
                            x: .value("Day", day.date, unit: .day),
                            y: .value("Minutes", day.minutes)
                        )
                        .foregroundStyle(
                            day.minutes <= goalMinutes
                                ? AdKanTheme.brandGreen
                                : AdKanTheme.dangerRed
                        )
                        .cornerRadius(2)
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day, count: 7)) { value in
                            if let date = value.as(Date.self) {
                                AxisValueLabel {
                                    Text(dayFormatter.string(from: date))
                                        .font(.caption2)
                                }
                            }
                        }
                    }
                    .frame(height: 180)

                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Circle().fill(AdKanTheme.brandGreen).frame(width: 8, height: 8)
                            Text("monthly.underGoal")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        HStack(spacing: 4) {
                            Circle().fill(AdKanTheme.dangerRed).frame(width: 8, height: 8)
                            Text("monthly.overGoal")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private func highlightsCard(_ data: MonthlySummaryData) -> some View {
        PlainCard {
            VStack(spacing: 14) {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                    Text("monthly.highlights")
                        .font(AdKanTheme.cardTitle)
                    Spacer()
                }

                if let best = data.bestDay {
                    highlightRow(
                        icon: "trophy.fill",
                        color: AdKanTheme.successGreen,
                        titleKey: "monthly.bestDay",
                        value: "\(dayFormatter.string(from: best.date)) — \(formatMinutes(best.minutes))"
                    )
                }

                if let worst = data.worstDay, data.dailyBreakdown.count > 1 {
                    highlightRow(
                        icon: "chart.line.uptrend.xyaxis",
                        color: AdKanTheme.warningOrange,
                        titleKey: "monthly.worstDay",
                        value: "\(dayFormatter.string(from: worst.date)) — \(formatMinutes(worst.minutes))"
                    )
                }
            }
        }
    }

    private func highlightRow(icon: String, color: Color, titleKey: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey(titleKey))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.weight(.medium))
            }
            Spacer()
        }
    }

    private func encouragementCard(_ data: MonthlySummaryData) -> some View {
        GradientCard(gradient: data.improved ? AdKanTheme.primaryGradient : AdKanTheme.heroGradient) {
            VStack(spacing: 8) {
                Text(data.improved ? "monthly.encouragement.improved" : "monthly.encouragement.keepGoing")
                    .font(AdKanTheme.cardTitle)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private func loadData() async {
        let builder = MonthlySummaryBuilder(scoreSync: services.scoreSync, goalMinutes: goalMinutes)
        data = await builder.build(for: Date())
        isLoading = false
    }

    private func formatMinutes(_ minutes: Int) -> String {
        TimeFormatter.format(minutes: minutes, locale: languageManager.preferredLanguage)
    }

    private func formatHours(_ minutes: Int) -> String {
        TimeFormatter.format(minutes: minutes, locale: languageManager.preferredLanguage)
    }
}
