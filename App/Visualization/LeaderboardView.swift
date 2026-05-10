import SwiftUI

enum LeaderboardTimeframe: String, CaseIterable {
    case daily
    case weekly

    var labelKey: String {
        switch self {
        case .daily: return "leaderboard.today"
        case .weekly: return "leaderboard.thisWeek"
        }
    }
}

struct LeaderboardView: View {
    let group: AdKanGroup
    let previousRanks: [String: Int]
    var compact: Bool = false
    @EnvironmentObject private var services: ServiceContainer
    @EnvironmentObject private var languageManager: LanguageManager
    @EnvironmentObject private var storeManager: StoreManager
    @State private var timeframe: LeaderboardTimeframe = .daily
    @State private var showPaywall = false
    @State private var weeklyEntries: [WeeklyLeaderboardEntry] = []
    @State private var weeklyLoaded = false

    private var dailyMembers: [GroupMember] {
        group.members.sorted { ($0.rank ?? 999) < ($1.rank ?? 999) }
    }

    private var podiumEntries: [PodiumEntry] {
        let source = dailyMembers
        return source.prefix(3).map { member in
            PodiumEntry(
                id: member.userId,
                displayName: member.displayName,
                avatarEmoji: member.avatarEmoji,
                minutes: member.dailyTotalMinutes ?? 0,
                streak: member.currentStreak ?? 0,
                leagueBadge: member.badge,
                rank: member.rank ?? 0,
                isCurrentUser: member.isCurrentUser
            )
        }
    }

    private var weeklyPodiumEntries: [PodiumEntry] {
        weeklyEntries.prefix(3).map { entry in
            PodiumEntry(
                id: entry.userId,
                displayName: entry.displayName,
                avatarEmoji: entry.avatarEmoji,
                minutes: entry.weeklyTotalMinutes,
                streak: entry.currentStreak,
                leagueBadge: entry.badge,
                rank: entry.rank,
                isCurrentUser: entry.userId == services.auth.currentUserId
            )
        }
    }

    private var remainingDaily: [GroupMember] {
        Array(dailyMembers.dropFirst(3))
    }

    private var remainingWeekly: [WeeklyLeaderboardEntry] {
        Array(weeklyEntries.dropFirst(3))
    }

    var body: some View {
        VStack(spacing: 14) {
            if !compact {
                timeframePicker
            }

            let entries = timeframe == .daily ? podiumEntries : weeklyPodiumEntries
            if entries.count >= 2 {
                PodiumView(entries: entries, formatMinutes: { formatMinutes($0) })
            }

            if !compact {
                remainingList
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(context: .general)
        }
        .task {
            await loadWeekly()
        }
    }

    private var timeframePicker: some View {
        Picker("", selection: $timeframe) {
            Text(LocalizedStringKey(LeaderboardTimeframe.daily.labelKey)).tag(LeaderboardTimeframe.daily)
            HStack {
                Text(LocalizedStringKey(LeaderboardTimeframe.weekly.labelKey))
                if !storeManager.isPremium {
                    Image(systemName: "lock.fill")
                }
            }.tag(LeaderboardTimeframe.weekly)
        }
        .pickerStyle(.segmented)
        .onChange(of: timeframe) { _, newValue in
            if newValue == .weekly {
                if !storeManager.isPremium {
                    timeframe = .daily
                    showPaywall = true
                } else if !weeklyLoaded {
                    Task { await loadWeekly() }
                }
            }
        }
    }

    @ViewBuilder
    private var remainingList: some View {
        if timeframe == .daily {
            ForEach(remainingDaily) { member in
                memberRow(
                    rank: member.rank ?? 0,
                    avatar: member.avatarEmoji,
                    name: member.displayName,
                    minutes: member.dailyTotalMinutes ?? 0,
                    streak: member.currentStreak ?? 0,
                    badge: member.badge,
                    isCurrentUser: member.isCurrentUser,
                    userId: member.userId
                )
            }
        } else {
            ForEach(remainingWeekly) { entry in
                memberRow(
                    rank: entry.rank,
                    avatar: entry.avatarEmoji,
                    name: entry.displayName,
                    minutes: entry.weeklyTotalMinutes,
                    streak: entry.currentStreak,
                    badge: entry.badge,
                    isCurrentUser: entry.userId == services.auth.currentUserId,
                    userId: entry.userId
                )
            }
        }
    }

    private func memberRow(
        rank: Int,
        avatar: String,
        name: String,
        minutes: Int,
        streak: Int,
        badge: LeagueBadge,
        isCurrentUser: Bool,
        userId: String
    ) -> some View {
        HStack(spacing: 12) {
            Text("#\(rank)")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
                .frame(width: 30, alignment: .leading)

            Text(avatar)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(name)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(isCurrentUser ? AdKanTheme.brandGreen : .primary)

                    if badge.displayable {
                        Text(badge.emoji)
                            .font(.system(size: 11))
                    }
                }

                if streak > 0 {
                    HStack(spacing: 2) {
                        Text("🔥")
                            .font(.system(size: 9))
                        Text("\(streak)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            if minutes > 0 {
                Text(formatMinutes(minutes))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AdKanTheme.minutesColor(timeframe == .weekly ? minutes / 7 : minutes))
            } else {
                Text("---")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }

            RankChangeIndicator(
                previousRank: previousRanks[userId],
                currentRank: rank
            )
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 14)
        .background(
            isCurrentUser
                ? RoundedRectangle(cornerRadius: 10).fill(AdKanTheme.brandGreen.opacity(0.08))
                : RoundedRectangle(cornerRadius: 10).fill(Color.clear)
        )
    }

    private func formatMinutes(_ minutes: Int) -> String {
        TimeFormatter.format(minutes: minutes, locale: languageManager.preferredLanguage)
    }

    private func loadWeekly() async {
        guard !weeklyLoaded else { return }
        weeklyEntries = (try? await services.leaderboard.fetchWeeklyLeaderboard(weekStart: nil)) ?? []
        weeklyLoaded = true
    }
}
