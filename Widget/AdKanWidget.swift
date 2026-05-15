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

    var statusColor: Color {
        WidgetTheme.minutesColor(todayMinutes, goal: goalMinutes)
    }

    var mascotImage: String {
        WidgetTheme.mascotImage(todayMinutes: todayMinutes, goalMinutes: goalMinutes)
    }

    var mascotGlowColor: Color {
        WidgetTheme.mascotGlowColor(todayMinutes: todayMinutes, goalMinutes: goalMinutes)
    }

    var stateLabelKey: String {
        WidgetTheme.stateLabel(todayMinutes: todayMinutes, goalMinutes: goalMinutes)
    }

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
    @Environment(\.colorScheme) private var colorScheme

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
                .stroke(entry.statusColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text({
                let isHebrew = Locale.current.language.languageCode?.identifier.hasPrefix("he") == true
                return "\(entry.todayMinutes)\(isHebrew ? "ד׳" : "m")"
            }())
                .font(.system(size: 13, weight: .bold, design: .rounded))
        }
    }

    // MARK: - Small Widget (Mascot Hero)

    private var smallView: some View {
        VStack(spacing: 4) {
            HStack {
                if entry.currentStreak > 0 {
                    streakPill
                }
                Spacer()
                Text(formatMinutes(entry.todayMinutes))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(entry.statusColor)
            }

            Spacer()

            ZStack {
                Circle()
                    .fill(entry.mascotGlowColor.opacity(0.15))
                    .frame(width: 85, height: 85)

                Image(entry.mascotImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 75)
            }

            Spacer()

            Text(NSLocalizedString(entry.stateLabelKey, comment: ""))
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(entry.mascotGlowColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(entry.mascotGlowColor.opacity(0.12))
                .clipShape(Capsule())
        }
        .padding(14)
        .containerBackground(for: .widget) {
            entry.mascotGlowColor.opacity(0.04)
        }
    }

    // MARK: - Medium Widget (Brain + Metrics)

    private var mediumView: some View {
        HStack(spacing: 12) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(entry.mascotGlowColor.opacity(0.15))
                        .frame(width: 80, height: 80)

                    Image(entry.mascotImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 68, height: 68)
                }

                Text(NSLocalizedString(entry.stateLabelKey, comment: ""))
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(entry.mascotGlowColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(entry.mascotGlowColor.opacity(0.12))
                    .clipShape(Capsule())
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("AdKan")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(formatMinutes(entry.todayMinutes))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(entry.statusColor)
                    Text("/ \(formatMinutes(entry.goalMinutes))")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                ProgressView(value: entry.usageRatio)
                    .tint(entry.statusColor)

                HStack(spacing: 12) {
                    if entry.currentStreak > 0 {
                        HStack(spacing: 3) {
                            Text("🔥")
                                .font(.system(size: 12))
                            Text("\(entry.currentStreak)")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                        }
                    }

                    if entry.yesterdayMinutes > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: entry.yesterdayDelta <= 0 ? "arrow.down.right" : "arrow.up.right")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(entry.yesterdayDelta <= 0 ? WidgetTheme.successGreen : WidgetTheme.dangerRed)
                            Text(deltaText)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .containerBackground(for: .widget) {
            entry.mascotGlowColor.opacity(0.04)
        }
    }

    // MARK: - Helpers

    private var streakPill: some View {
        HStack(spacing: 3) {
            Text("🔥")
                .font(.system(size: 10))
            Text("\(entry.currentStreak)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(Color(.secondarySystemBackground))
        .clipShape(Capsule())
    }

    private var deltaText: String {
        let abs = abs(entry.yesterdayDelta)
        let formatted = formatMinutes(abs)
        let isHebrew = Locale.current.language.languageCode?.identifier.hasPrefix("he") == true
        let less = isHebrew ? "פחות" : "less"
        let more = isHebrew ? "יותר" : "more"
        return entry.yesterdayDelta <= 0
            ? "\(formatted) \(less)"
            : "\(formatted) \(more)"
    }

    private func formatMinutes(_ minutes: Int) -> String {
        let h = minutes / 60, m = minutes % 60
        let isHebrew = Locale.current.language.languageCode?.identifier.hasPrefix("he") == true

        if isHebrew {
            let hp: String = h == 1 ? "שעה" : h == 2 ? "שעתיים" : "\(h) שעות"
            let mp: String = m == 1 ? "דקה" : "\(m) דקות"
            if h > 0 && m > 0 { return "\u{200F}\(hp) ו\u{2011}\(mp)\u{200F}" }
            if h > 0 { return "\u{200F}\(hp)\u{200F}" }
            return "\u{200F}\(mp)\u{200F}"
        } else {
            if h > 0 && m > 0 { return "\(h)h \(m)m" }
            if h > 0 { return "\(h)h" }
            return "\(m)m"
        }
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

// MARK: - Previews

#Preview("Small — Thriving", as: .systemSmall) {
    AdKanWidget()
} timeline: {
    AdKanEntry(date: Date(), todayMinutes: 40, goalMinutes: 120, currentStreak: 14, yesterdayMinutes: 55)
}

#Preview("Small — Spiraling", as: .systemSmall) {
    AdKanWidget()
} timeline: {
    AdKanEntry(date: Date(), todayMinutes: 420, goalMinutes: 120, currentStreak: 0, yesterdayMinutes: 380)
}

#Preview("Medium — On Track", as: .systemMedium) {
    AdKanWidget()
} timeline: {
    AdKanEntry(date: Date(), todayMinutes: 95, goalMinutes: 120, currentStreak: 5, yesterdayMinutes: 110)
}

#Preview("Lock Screen", as: .accessoryCircular) {
    AdKanWidget()
} timeline: {
    AdKanEntry(date: Date(), todayMinutes: 72, goalMinutes: 120, currentStreak: 5, yesterdayMinutes: 90)
}
