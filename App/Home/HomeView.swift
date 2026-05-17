import SwiftUI
import WidgetKit
#if canImport(FamilyControls)
import FamilyControls
#endif

struct HomeView: View {
    @Environment(\.screenTimeProvider) private var provider
    @Environment(\.switchToFocusTab) private var switchToFocusTab
    @Environment(\.scenePhase) private var scenePhase
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
    @State private var bridgeRefreshID = UUID()
    @State private var cardsAppeared = false
    @State private var showSignIn = false

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
                #if canImport(DeviceActivity) && !targetEnvironment(simulator)
                ScreenTimeReportBridge()
                    .id(bridgeRefreshID)
                #endif

                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 300)
                } else {
                    VStack(spacing: AdKanTheme.cardSpacing) {
                        MascotView(todayMinutes: todayMinutes, goalMinutes: goalMinutes)

                        if !services.auth.isAuthenticated {
                            signInBanner
                        }

                        #if canImport(FamilyControls) && !targetEnvironment(simulator)
                        if todayMinutes == 0 {
                            screenTimeDiagnosticBanner
                        }
                        #endif

                        TimeReclaimedView(savedMinutes: savedMinutes, goalMinutes: goalMinutes, todayMinutes: todayMinutes)

                        if let rank = currentUserRank, let group = favoriteGroup {
                            rankChip(rank: rank, groupName: group.name, groupId: group.id)
                        }

                        HStack(spacing: 6) {
                            Image(systemName: "chart.bar.fill")
                                .font(.caption)
                                .foregroundStyle(AdKanTheme.primary)
                            Text("home.todayMetrics")
                                .font(AdKanTheme.cardTitle)
                            Spacer()
                        }

                        usageCard

                        focusCTA

                        StreakCalendarView()

                        PlainCard {
                            VStack(spacing: 8) {
                                HStack {
                                    Image(systemName: "flame.fill")
                                        .foregroundStyle(AdKanTheme.primary)
                                        .padding(6)
                                        .background(AdKanTheme.primary.opacity(0.12))
                                        .clipShape(Circle())
                                    Text("home.dailyGoal")
                                        .font(AdKanTheme.cardTitle)
                                    Spacer()
                                }
                                ProgressBarView(currentMinutes: todayMinutes, goalMinutes: goalMinutes, compact: false)
                            }
                        }

                        if let group = favoriteGroup ?? groups.first {
                            leaderboardPreview(group: group)
                        } else {
                            noGroupsCTA
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
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .groupDetail(let groupId):
                    GroupDetailView(groupId: groupId)
                case .createGroup:
                    CreateGroupView(onCreated: { newGroup in
                        groups.append(newGroup)
                    })
                default:
                    EmptyView()
                }
            }
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
                scheduleDataDrivenNotifications()
                updateWidget()
                LocalScoreStore.save(minutes: todayMinutes, for: Date())
            }
            .sheet(isPresented: $showSignIn) {
                SignInView {
                    showSignIn = false
                    Task { await refreshData() }
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    bridgeRefreshID = UUID()
                    Task {
                        try? await Task.sleep(for: .seconds(1))
                        let fresh = await provider.todayTotalMinutes()
                        if fresh > 0 { todayMinutes = fresh }
                        let freshYesterday = await provider.yesterdayTotalMinutes()
                        if freshYesterday > 0 { yesterdayMinutes = freshYesterday }
                    }
                }
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
                LocalScoreStore.save(minutes: todayMinutes, for: Date())
                scheduleDataDrivenNotifications()
                detectRankChange()
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
            VStack(spacing: 10) {
                Text(TimeFormatter.format(minutes: todayMinutes, locale: languageManager.preferredLanguage))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(AdKanTheme.minutesColor(todayMinutes, goal: goalMinutes))

                Text("home.minToday")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Divider()

                HStack {
                    let delta = todayMinutes - yesterdayMinutes
                    HStack(spacing: 3) {
                        Image(systemName: delta <= 0 ? "arrow.down.right" : "arrow.up.right")
                            .font(.system(size: 10, weight: .bold))
                        Text(TimeFormatter.format(minutes: abs(delta), locale: languageManager.preferredLanguage))
                            .font(.caption.weight(.semibold))
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
                    }
                    .foregroundStyle(delta <= 0 ? AdKanTheme.successGreen : AdKanTheme.dangerRed)

                    Text("home.vsYesterday")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Spacer()

                    HStack(spacing: 3) {
                        Image(systemName: "target")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(AdKanTheme.primary)
                        Text(TimeFormatter.format(minutes: goalMinutes, locale: languageManager.preferredLanguage))
                            .font(.caption.weight(.semibold))
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .multilineTextAlignment(.center)
        }
    }

    private var focusCTA: some View {
        AdKanButton(titleKey: "home.startFocus", style: .primary) {
            switchToFocusTab()
        }
    }

    private func leaderboardPreview(group: AdKanGroup) -> some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(AdKanTheme.primary)
                    .font(.caption)
                Text("home.leaderboard")
                    .font(AdKanTheme.cardTitle)
                Spacer()
                NavigationLink(value: Route.groupDetail(groupId: group.id)) {
                    HStack(spacing: 4) {
                        Text("home.seeAll")
                            .font(.caption.bold())
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(AdKanTheme.primary)
                }
            }

            LeaderboardView(group: group, previousRanks: [:], compact: true)
        }
    }

    private func scheduleDataDrivenNotifications() {
        let streak = streakTracker.currentStreak

        if UserDefaults.standard.object(forKey: "goalCelebrationEnabled") as? Bool ?? true {
            if todayMinutes <= goalMinutes && todayMinutes > 0 {
                NotificationManager.shared.scheduleGoalCelebration(
                    savedMinutes: goalMinutes - todayMinutes,
                    streak: streak
                )
            } else {
                NotificationManager.shared.cancelGoalCelebration()
            }
        }

        if UserDefaults.standard.bool(forKey: "eveningReminderEnabled") {
            NotificationManager.shared.scheduleEveningReminder(
                todayMinutes: todayMinutes,
                goalMinutes: goalMinutes
            )
        }

        if UserDefaults.standard.object(forKey: "inactivityReminderEnabled") as? Bool ?? true {
            NotificationManager.shared.scheduleInactivityReengagement(
                groupName: favoriteGroup?.name,
                lastRank: currentUserRank,
                streak: streak
            )
        }

        let weeklyEnabled = UserDefaults.standard.object(forKey: "weeklyCheckinEnabled") as? Bool ?? true
        if weeklyEnabled {
            NotificationManager.shared.scheduleWeeklyCheckIn(
                friendName: nil,
                streak: streak,
                groupName: favoriteGroup?.name
            )
        }
    }

    private func detectRankChange() {
        guard let group = favoriteGroup,
              let userId = services.auth.currentUserId,
              let member = group.members.first(where: { $0.userId == userId }),
              let currentRank = member.rank else { return }

        let previousRank = RankHistoryStore.shared.previousRank(for: userId, groupId: group.id)
        guard let oldRank = previousRank, oldRank != currentRank else { return }

        NotificationManager.shared.sendRankChangeAlert(
            groupName: group.name,
            oldRank: oldRank,
            newRank: currentRank
        )
    }

    private var signInBanner: some View {
        PlainCard {
            VStack(spacing: 10) {
                Image(systemName: "person.crop.circle.badge.checkmark")
                    .font(.title2)
                    .foregroundStyle(AdKanTheme.primary)

                Text("signin.prompt.title")
                    .font(.subheadline.weight(.medium))
                    .multilineTextAlignment(.center)

                Button {
                    showSignIn = true
                } label: {
                    Text("signin.prompt.cta")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.black)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: AdKanTheme.buttonCornerRadius))
                }
            }
        }
    }

    #if canImport(FamilyControls) && !targetEnvironment(simulator)
    private var screenTimeDiagnosticBanner: some View {
        let fileURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.talhayun.AdKan")?
            .appendingPathComponent("report-data.plist")
        let dict = fileURL.flatMap { NSDictionary(contentsOf: $0) }

        let lastRun = dict?["lastRun"] as? Double ?? 0
        let lastRunStr = lastRun > 0
            ? DateFormatter.localizedString(from: Date(timeIntervalSince1970: lastRun), dateStyle: .none, timeStyle: .medium)
            : "never"
        let raw = dict?["todayMinutes"] as? Int ?? -1
        let phase = dict?["phase"] as? String ?? "none"
        let segments = dict?["segmentCount"] as? Int ?? -1
        let authStatus = AuthorizationCenter.shared.authorizationStatus

        return PlainCard {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("Screen Time Debug")
                        .font(.caption.bold())
                }
                Text("Phase: \(phase)")
                    .font(.caption2)
                Text("makeConfig ran: \(lastRunStr)")
                    .font(.caption2)
                Text("Segments: \(segments), Minutes: \(raw)")
                    .font(.caption2)
                Text("Auth: \(String(describing: authStatus))")
                    .font(.caption2)
                Text("File: \(dict != nil ? "readable" : "missing")")
                    .font(.caption2)
                    .foregroundStyle(dict != nil ? .green : .red)
            }
        }
    }
    #endif

    private var noGroupsCTA: some View {
        PlainCard {
            VStack(spacing: 12) {
                Image(systemName: "person.3.fill")
                    .font(.title)
                    .foregroundStyle(AdKanTheme.primary)

                Text("home.noGroups.title")
                    .font(AdKanTheme.cardTitle)
                    .multilineTextAlignment(.center)

                Text("home.noGroups.body")
                    .font(AdKanTheme.cardBody)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                NavigationLink(value: Route.createGroup) {
                    Text("home.noGroups.cta")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AdKanTheme.primaryGradient)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: AdKanTheme.buttonCornerRadius))
                }
            }
        }
    }
}
