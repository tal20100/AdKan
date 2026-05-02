// [SKILL-DECL] Consulted WidgetKit docs + AdKanTheme design tokens + Widget/SharedDefaults.swift
import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct AdKanEntry: TimelineEntry {
    let date: Date
    let todayMinutes: Int
    let goalMinutes: Int
    let currentStreak: Int

    var usageRatio: Double {
        goalMinutes > 0 ? min(Double(todayMinutes) / Double(goalMinutes), 1.0) : 0
    }

    static let placeholder = AdKanEntry(date: Date(), todayMinutes: 72, goalMinutes: 120, currentStreak: 5)
}

// MARK: - Timeline Provider

struct AdKanProvider: TimelineProvider {
    func placeholder(in context: Context) -> AdKanEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (AdKanEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AdKanEntry>) -> Void) {
        let entry = currentEntry()
        // Refresh every 15 minutes so the ring stays current
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private func currentEntry() -> AdKanEntry {
        AdKanEntry(
            date: Date(),
            todayMinutes: SharedDefaults.todayMinutes,
            goalMinutes: SharedDefaults.goalMinutes,
            currentStreak: SharedDefaults.currentStreak
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
        default:
            homeScreenView
        }
    }

    // Lock screen: compact ring only
    private var lockScreenView: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 4)
            Circle()
                .trim(from: 0, to: entry.usageRatio)
                .stroke(ringColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(entry.todayMinutes)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
        }
    }

    // Home screen small widget: ring + streak
    private var homeScreenView: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.15), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: entry.usageRatio)
                    .stroke(ringColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.8), value: entry.usageRatio)

                VStack(spacing: 2) {
                    Text(formatMinutes(entry.todayMinutes))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("used")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .frame(width: 80, height: 80)

            if entry.currentStreak > 0 {
                HStack(spacing: 3) {
                    Text("🔥")
                        .font(.system(size: 12))
                    Text("\(entry.currentStreak)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundGradient)
    }

    private var ringColor: Color {
        entry.todayMinutes <= entry.goalMinutes
            ? Color(red: 0.471, green: 0.788, blue: 0.435)   // brandGreen
            : Color(red: 0.95, green: 0.25, blue: 0.3)        // dangerRed
    }

    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.118, green: 0.122, blue: 0.125), Color(red: 0.122, green: 0.306, blue: 0.435)],
            startPoint: .top, endPoint: .bottom
        )
    }

    private func formatMinutes(_ minutes: Int) -> String {
        let h = minutes / 60, m = minutes % 60
        return h > 0 ? "\(h)h\(m)m" : "\(m)m"
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
        .supportedFamilies([.systemSmall, .accessoryCircular])
    }
}
