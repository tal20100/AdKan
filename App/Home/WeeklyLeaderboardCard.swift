// [SKILL-DECL] Consulted App/Home/WeeklySummaryCard.swift for data-fetch pattern + App/Home/FavoriteGroupCard.swift for leaderboard display
import SwiftUI

struct WeeklyLeaderboardCard: View {
    let group: AdKanGroup
    @EnvironmentObject private var services: ServiceContainer
    @EnvironmentObject private var storeManager: StoreManager
    @State private var weeklyTotals: [String: Int] = [:]   // userId → weekly minutes
    @State private var loaded = false

    private let calendar = Calendar.current

    /// Members sorted by weekly total (lowest = winner)
    private var rankedMembers: [(member: GroupMember, weeklyMinutes: Int)] {
        group.members
            .map { member in (member: member, weeklyMinutes: weeklyTotals[member.userId] ?? 0) }
            .sorted { $0.weeklyMinutes < $1.weeklyMinutes }
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "flag.checkered")
                    .foregroundStyle(AdKanTheme.primary)
                    .font(.caption)
                Text("home.weeklyLeaderboard")
                    .font(AdKanTheme.cardTitle)
                Spacer()
                Text("home.weeklyLeaderboard.resets")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            PlainCard {
                VStack(spacing: 8) {
                    if loaded {
                        ForEach(Array(rankedMembers.enumerated()), id: \.element.member.userId) { index, entry in
                            HStack(spacing: 12) {
                                rankBadge(index + 1)
                                    .frame(width: 28, alignment: .leading)

                                Text(entry.member.avatarEmoji)
                                    .font(.title3)

                                Text(entry.member.displayName)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(entry.member.isCurrentUser ? AdKanTheme.brandGreen : .primary)

                                Spacer()

                                Text(String(format: NSLocalizedString("home.weeklyLeaderboard.total", comment: ""), entry.weeklyMinutes))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AdKanTheme.minutesColor(entry.weeklyMinutes / 7))
                            }
                        }
                    } else {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 60)
                    }
                }
            }
        }
        .task { await loadWeeklyTotals() }
    }

    @ViewBuilder
    private func rankBadge(_ rank: Int) -> some View {
        switch rank {
        case 1: Image(systemName: "medal.fill").foregroundStyle(.yellow).font(.system(size: 16))
        case 2: Image(systemName: "medal.fill").foregroundStyle(Color(white: 0.75)).font(.system(size: 16))
        case 3: Image(systemName: "medal.fill").foregroundStyle(Color(red: 0.8, green: 0.5, blue: 0.2)).font(.system(size: 16))
        default: Text("#\(rank)").font(.system(size: 14, weight: .bold, design: .rounded)).foregroundStyle(.secondary)
        }
    }

    private func loadWeeklyTotals() async {
        let today = calendar.startOfDay(for: Date())
        let thisWeekDays: [Date] = (0..<7).compactMap {
            calendar.date(byAdding: .day, value: -$0, to: today)
        }

        // Fetch all members' daily scores for each of the last 7 days, sum per member
        var totals: [String: Int] = [:]
        await withTaskGroup(of: [LeaderboardEntry].self) { taskGroup in
            for day in thisWeekDays {
                taskGroup.addTask {
                    (try? await services.leaderboard.fetchLeaderboard(for: day)) ?? []
                }
            }
            for await entries in taskGroup {
                for entry in entries {
                    totals[entry.userId, default: 0] += entry.dailyTotalMinutes
                }
            }
        }
        weeklyTotals = totals
        loaded = true
    }
}
