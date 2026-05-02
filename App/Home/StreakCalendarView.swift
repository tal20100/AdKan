// [SKILL-DECL] Consulted mobile-ios-design skill + AdKanTheme design tokens + App/Models/StreakTracker.swift
import SwiftUI

/// 5-week dot grid showing the last 35 days — green when goal was met, gray when missed.
/// Replaces the plain streak number card with a visual habit chain.
struct StreakCalendarView: View {
    @EnvironmentObject private var streakTracker: StreakTracker

    private let columns = 7
    private let rows = 5
    private let dotSize: CGFloat = 10
    private let dotSpacing: CGFloat = 8
    private let calendar = Calendar.current

    /// Last 35 days ending today, oldest first (left→right, top→bottom)
    private var days: [Date] {
        let today = calendar.startOfDay(for: Date())
        return (0..<(columns * rows)).reversed().compactMap {
            calendar.date(byAdding: .day, value: -$0, to: today)
        }
    }

    var body: some View {
        PlainCard {
            VStack(spacing: 12) {
                HStack {
                    Text("home.streakCalendar.title")
                        .font(AdKanTheme.cardTitle)
                    Spacer()
                    streakBadge
                }

                dotGrid

                if streakTracker.longestStreak > 0 {
                    Text("home.streakBest \(streakTracker.longestStreak)" as LocalizedStringKey)
                        .font(AdKanTheme.cardBody)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var streakBadge: some View {
        HStack(spacing: 4) {
            Text("🔥")
                .font(.system(size: 16))
            Text("\(streakTracker.currentStreak)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(AdKanTheme.brandGreen)
        }
    }

    private var dotGrid: some View {
        let goalDays = streakTracker.goalMetDays
        return LazyVGrid(
            columns: Array(repeating: GridItem(.fixed(dotSize), spacing: dotSpacing), count: columns),
            spacing: dotSpacing
        ) {
            ForEach(days, id: \.self) { day in
                Circle()
                    .fill(goalDays.contains(day) ? AdKanTheme.brandGreen : Color(.systemGray5))
                    .frame(width: dotSize, height: dotSize)
                    .scaleEffect(goalDays.contains(day) ? 1.15 : 1.0)
                    .animation(.spring(response: 0.3), value: goalDays.contains(day))
            }
        }
    }
}
