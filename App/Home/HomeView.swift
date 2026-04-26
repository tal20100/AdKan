import SwiftUI

struct HomeView: View {
    @Environment(\.screenTimeProvider) private var provider
    @EnvironmentObject private var services: ServiceContainer
    @EnvironmentObject private var streakTracker: StreakTracker
    @AppStorage("dailyGoalMinutes") private var goalMinutes: Int = 120
    @State private var todayMinutes: Int = 0
    @State private var yesterdayMinutes: Int = 0
    @State private var groups: [AdKanGroup] = []
    @State private var isLoading = true
    @State private var loadError: String?

    private var savedMinutes: Int {
        max(0, (24 * 60) - todayMinutes)
    }

    private var favoriteGroup: AdKanGroup? {
        groups.first { $0.isFavorite }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 300)
                } else {
                    VStack(spacing: AdKanTheme.cardSpacing) {
                        MascotView(todayMinutes: todayMinutes, goalMinutes: goalMinutes)

                        TimeReclaimedView(savedMinutes: savedMinutes, goalMinutes: goalMinutes)

                        usageCard

                        if streakTracker.currentStreak > 0 {
                            streakCard
                        }

                        PlainCard {
                            VStack(spacing: 8) {
                                HStack {
                                    Image(systemName: "flame.fill")
                                        .foregroundStyle(AdKanTheme.primary)
                                    Text("home.dailyGoal")
                                        .font(AdKanTheme.cardTitle)
                                    Spacer()
                                }
                                ProgressBarView(currentMinutes: todayMinutes, goalMinutes: goalMinutes, compact: false)
                            }
                        }

                        FavoriteGroupCard(group: favoriteGroup)

                        WeeklySummaryCard()
                    }
                    .padding(.horizontal, AdKanTheme.screenPadding)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(Text("app.displayName"))
            .refreshable {
                await refreshData()
            }
            .task {
                todayMinutes = await provider.todayTotalMinutes()
                yesterdayMinutes = await provider.yesterdayTotalMinutes()
                do {
                    groups = try await services.groups.fetchMyGroups()
                } catch {
                    loadError = error.localizedDescription
                }
                if todayMinutes <= goalMinutes && todayMinutes > 0 {
                    streakTracker.recordGoalMet()
                    let streak = streakTracker.currentStreak
                    if [3, 7, 14, 30].contains(streak) {
                        NotificationManager.shared.sendStreakMilestone(days: streak)
                    }
                }
                isLoading = false
            }
        }
    }

    private func refreshData() async {
        todayMinutes = await provider.todayTotalMinutes()
        yesterdayMinutes = await provider.yesterdayTotalMinutes()
        groups = (try? await services.groups.fetchMyGroups()) ?? groups
    }

    private var streakCard: some View {
        PlainCard {
            HStack(spacing: 16) {
                Text("🔥")
                    .font(.system(size: 36))

                VStack(alignment: .leading, spacing: 4) {
                    Text("home.streak \(streakTracker.currentStreak)")
                        .font(AdKanTheme.cardTitle)
                    if streakTracker.longestStreak > streakTracker.currentStreak {
                        Text("home.streakBest \(streakTracker.longestStreak)")
                            .font(AdKanTheme.cardBody)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if streakTracker.currentStreak >= 7 {
                    Image(systemName: "medal.fill")
                        .font(.title2)
                        .foregroundStyle(.yellow)
                }
            }
        }
    }

    private var usageCard: some View {
        PlainCard {
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("\(todayMinutes)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(AdKanTheme.minutesColor(todayMinutes, goal: goalMinutes))
                    Text("home.minToday")
                        .font(AdKanTheme.cardBody)
                        .foregroundStyle(.secondary)
                }

                Divider()
                    .frame(height: 48)

                VStack(spacing: 4) {
                    let delta = todayMinutes - yesterdayMinutes
                    HStack(spacing: 4) {
                        Image(systemName: delta <= 0 ? "arrow.down.right" : "arrow.up.right")
                            .font(.caption.bold())
                        Text("\(abs(delta))m")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(delta <= 0 ? AdKanTheme.successGreen : AdKanTheme.dangerRed)

                    Text("home.vsYesterday")
                        .font(AdKanTheme.cardBody)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(spacing: 4) {
                    Image(systemName: "target")
                        .font(.title2)
                        .foregroundStyle(AdKanTheme.primary)
                    Text("\(goalMinutes)m")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
