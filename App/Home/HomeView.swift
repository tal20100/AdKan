import SwiftUI
import WidgetKit

struct HomeView: View {
    @Environment(\.screenTimeProvider) private var provider
    @Environment(\.switchToFocusTab) private var switchToFocusTab
    @EnvironmentObject private var services: ServiceContainer
    @EnvironmentObject private var languageManager: LanguageManager
    @EnvironmentObject private var streakTracker: StreakTracker
    @AppStorage("dailyGoalMinutes") private var goalMinutes: Int = 120
    @State private var todayMinutes: Int = 0
    @State private var yesterdayMinutes: Int = 0
    @State private var groups: [AdKanGroup] = []
    @State private var isLoading = true
    @State private var loadError: String?
    @State private var pendingMilestone: Int? = nil
    @State private var cardsAppeared = false

    private static let milestoneDays = [7, 14, 30, 100]
    private let shownMilestonesKey = "shownMilestonesV1"

    private var shownMilestones: Set<Int> {
        Set(UserDefaults.standard.array(forKey: shownMilestonesKey) as? [Int] ?? [])
    }

    private var savedMinutes: Int {
        max(0, goalMinutes - todayMinutes)
    }

    private var favoriteGroup: AdKanGroup? {
        groups.first { $0.isFavorite }
    }

    private var currentUserRank: Int? {
        favoriteGroup?.members.first(where: { $0.isCurrentUser })?.rank
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

                        TimeReclaimedView(savedMinutes: savedMinutes, goalMinutes: goalMinutes, todayMinutes: todayMinutes)

                        if let rank = currentUserRank, let group = favoriteGroup {
                            rankChip(rank: rank, groupName: group.name, groupId: group.id)
                        }

                        usageCard

                        focusCTA

                        StreakCalendarView()

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

                        if let group = favoriteGroup {
                            WeeklyLeaderboardCard(group: group)
                        }

                        WeeklySummaryCard()

                        MonthlySummaryCard()
                    }
                    .padding(.horizontal, AdKanTheme.screenPadding)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                    .opacity(cardsAppeared ? 1 : 0)
                    .offset(y: cardsAppeared ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: cardsAppeared)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("AdKan")
            .overlay {
                if let milestone = pendingMilestone {
                    MilestoneShareSheet(streakDays: milestone) {
                        // Mark as shown so it doesn't re-appear
                        var shown = shownMilestones
                        shown.insert(milestone)
                        UserDefaults.standard.set(Array(shown), forKey: shownMilestonesKey)
                        pendingMilestone = nil
                    }
                    .transition(.opacity)
                    .zIndex(10)
                }
            }
            .onChange(of: todayMinutes) { oldValue, _ in
                NotificationManager.shared.rescheduleStreakAtRisk(
                    streak: streakTracker.currentStreak,
                    todayMinutes: todayMinutes,
                    goalMinutes: goalMinutes
                )
                let oldState = MascotState(todayMinutes: oldValue, goalMinutes: goalMinutes)
                let newState = MascotState(todayMinutes: todayMinutes, goalMinutes: goalMinutes)
                if oldState != newState && (newState == .warning || newState == .spiraling) {
                    UINotificationFeedbackGenerator().notificationOccurred(.warning)
                }
                updateWidget()
            }
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
                    let allMilestones = [3] + HomeView.milestoneDays
                    if allMilestones.contains(streak) {
                        // Day-3: local notification only (not worth a share card)
                        // Day 7/14/30/100: show in-app share card (once per milestone)
                        if HomeView.milestoneDays.contains(streak) {
                            if !shownMilestones.contains(streak) {
                                pendingMilestone = streak
                            }
                        } else {
                            NotificationManager.shared.sendStreakMilestone(days: streak)
                        }
                    }
                }
                updateWidget()
                isLoading = false
                withAnimation { cardsAppeared = true }
            }
        }
    }

    private func updateWidget() {
        SharedDefaults.todayMinutes = todayMinutes
        SharedDefaults.goalMinutes = goalMinutes
        SharedDefaults.currentStreak = streakTracker.currentStreak
        SharedDefaults.yesterdayMinutes = yesterdayMinutes
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func refreshData() async {
        todayMinutes = await provider.todayTotalMinutes()
        yesterdayMinutes = await provider.yesterdayTotalMinutes()
        groups = (try? await services.groups.fetchMyGroups()) ?? groups
    }

    @ViewBuilder
    private func rankChip(rank: Int, groupName: String, groupId: String) -> some View {
        NavigationLink(value: Route.groupDetail(groupId: groupId)) {
            HStack(spacing: 8) {
                Text("🏆")
                    .font(.system(size: 16))
                Text(String(format: NSLocalizedString("home.rankChip", comment: ""), rank, groupName))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: AdKanTheme.cardCornerRadius))
        }
        .buttonStyle(.plain)
    }

    private var usageCard: some View {
        PlainCard {
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text(TimeFormatter.format(minutes: todayMinutes, locale: languageManager.preferredLanguage))
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
                        Text(TimeFormatter.format(minutes: abs(delta), locale: languageManager.preferredLanguage))
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
                    Text(TimeFormatter.format(minutes: goalMinutes, locale: languageManager.preferredLanguage))
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var focusCTA: some View {
        AdKanButton(titleKey: "home.startFocus", style: .primary) {
            switchToFocusTab()
        }
    }
}
