import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct AdKanEntry: TimelineEntry {
    let date: Date
    let todayMinutes: Int
    let goalMinutes: Int
    let currentStreak: Int
    let yesterdayMinutes: Int

    var usageRatio: Double {
        goalMinutes > 0 ? min(Double(todayMinutes) / Double(goalMinutes), 1.0) : 0
    }

    var yesterdayDelta: Int { todayMinutes - yesterdayMinutes }

    static let placeholder = AdKanEntry(
        date: Date(), todayMinutes: 72, goalMinutes: 120,
        currentStreak: 5, yesterdayMinutes: 90
    )
}

// MARK: - Timeline Provider

struct AdKanProvider: TimelineProvider {
    func placeholder(in context: Context) -> AdKanEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (AdKanEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AdKanEntry>) -> Void) {
        let entry = currentEntry()
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private func currentEntry() -> AdKanEntry {
        AdKanEntry(
            date: Date(),
            todayMinutes: SharedDefaults.todayMinutes,
            goalMinutes: SharedDefaults.goalMinutes,
            currentStreak: SharedDefaults.currentStreak,
            yesterdayMinutes: SharedDefaults.yesterdayMinutes
        )
    }
}

// MARK: - Widget Views

struct AdKanWidgetEntryView: View {
    let entry: AdKanEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            lockScreenView
        case .systemMedium:
            mediumView
        default:
            smallView
        }
    }

    // MARK: - Lock Screen

    private var lockScreenView: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 4)
            Circle()
                .trim(from: 0, to: entry.usageRatio)
                .stroke(ringColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(entry.todayMinutes)m")
                .font(.system(size: 13, weight: .bold, design: .rounded))
        }
    }

    // MARK: - Small Widget

    private var smallView: some View {
        VStack(spacing: 6) {
            HStack {
                Image("WidgetBrainIcon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                Spacer()
                if entry.currentStreak > 0 {
                    streakPill
                }
            }

            Spacer()

            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: entry.usageRatio)
                    .stroke(
                        WidgetTheme.ringGradient,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                Circle()
                    .trim(from: 0, to: entry.usageRatio)
                    .stroke(ringColor.opacity(0.4), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .blur(radius: 6)

                VStack(spacing: 1) {
                    Text(formatMinutes(entry.todayMinutes))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("of \(formatMinutes(entry.goalMinutes))")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .frame(width: 80, height: 80)

            Spacer()
        }
        .padding(14)
        .containerBackground(for: .widget) {
            WidgetTheme.heroGradient
                .overlay(
                    RadialGradient(
                        colors: [WidgetTheme.brandGreen.opacity(0.08), .clear],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
        }
    }

    // MARK: - Medium Widget

    private var mediumView: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: entry.usageRatio)
                    .stroke(
                        WidgetTheme.ringGradient,
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                Circle()
                    .trim(from: 0, to: entry.usageRatio)
                    .stroke(ringColor.opacity(0.4), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .blur(radius: 6)

                VStack(spacing: 2) {
                    Text(formatMinutes(entry.todayMinutes))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("of \(formatMinutes(entry.goalMinutes))")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .frame(width: 90, height: 90)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 4) {
                    Image("WidgetBrainIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 18, height: 18)
                    Text("AdKan")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                }

                if entry.currentStreak > 0 {
                    HStack(spacing: 4) {
                        Text("🔥")
                            .font(.system(size: 13))
                        Text("\(entry.currentStreak) day streak")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }

                if entry.yesterdayMinutes > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: entry.yesterdayDelta <= 0 ? "arrow.down.right" : "arrow.up.right")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(entry.yesterdayDelta <= 0 ? WidgetTheme.brandGreen : WidgetTheme.dangerRed)
                        Text(deltaText)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .containerBackground(for: .widget) {
            WidgetTheme.heroGradient
                .overlay(
                    RadialGradient(
                        colors: [WidgetTheme.brandGreen.opacity(0.08), .clear],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
        }
    }

    // MARK: - Helpers

    private var streakPill: some View {
        HStack(spacing: 3) {
            Text("🔥")
                .font(.system(size: 10))
            Text("\(entry.currentStreak)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(Color.white.opacity(0.12))
        .clipShape(Capsule())
    }

    private var ringColor: Color {
        entry.todayMinutes <= entry.goalMinutes
            ? WidgetTheme.brandGreen
            : WidgetTheme.dangerRed
    }

    private var deltaText: String {
        let abs = abs(entry.yesterdayDelta)
        let formatted = formatMinutes(abs)
        return entry.yesterdayDelta <= 0
            ? "\(formatted) less than yesterday"
            : "\(formatted) more than yesterday"
    }

    private func formatMinutes(_ minutes: Int) -> String {
        let h = minutes / 60, m = minutes % 60
        if h > 0 && m > 0 { return "\(h)h\(m)m" }
        if h > 0 { return "\(h)h" }
        return "\(m)m"
    }
}

// MARK: - Widget Configuration

@main
struct AdKanWidgetBundle: WidgetBundle {
    var body: some Widget {
        AdKanWidget()
    }
}

struct AdKanWidget: Widget {
    let kind = "AdKanWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AdKanProvider()) { entry in
            AdKanWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("AdKan")
        .description("See your screen time at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular])
    }
}
