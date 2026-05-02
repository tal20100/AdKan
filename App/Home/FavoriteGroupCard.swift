import SwiftUI

struct FavoriteGroupCard: View {
    let group: AdKanGroup?

    var body: some View {
        if let group = group {
            groupLeaderboard(group)
        } else {
            emptyState
        }
    }

    private func groupLeaderboard(_ group: AdKanGroup) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                    .font(.caption)
                Text(group.name)
                    .font(AdKanTheme.cardTitle)
                Spacer()
                NavigationLink {
                    GroupDetailView(groupId: group.id)
                } label: {
                    Text("home.seeAll")
                        .font(.footnote.bold())
                        .foregroundStyle(AdKanTheme.primary)
                }
            }

            PlainCard {
                VStack(spacing: 8) {
                    ForEach(group.members.sorted(by: { ($0.rank ?? 999) < ($1.rank ?? 999) })) { member in
                        HStack(spacing: 12) {
                            rankBadge(member.rank ?? 0)
                                .frame(width: 28, alignment: .leading)

                            Text(member.avatarEmoji)
                                .font(.title3)

                            Text(member.displayName)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(member.isCurrentUser ? AdKanTheme.brandGreen : .primary)

                            Spacer()

                            if let minutes = member.dailyTotalMinutes {
                                Text("\(minutes)m")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AdKanTheme.minutesColor(minutes))
                            }

                            if let currentRank = member.rank {
                                RankChangeIndicator(
                                    previousRank: RankHistoryStore.shared.previousRank(for: member.userId, groupId: group.id),
                                    currentRank: currentRank
                                )
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func rankBadge(_ rank: Int) -> some View {
        switch rank {
        case 1:
            Image(systemName: "medal.fill")
                .foregroundStyle(.yellow)
                .font(.system(size: 16))
        case 2:
            Image(systemName: "medal.fill")
                .foregroundStyle(Color(white: 0.75))
                .font(.system(size: 16))
        case 3:
            Image(systemName: "medal.fill")
                .foregroundStyle(Color(red: 0.8, green: 0.5, blue: 0.2))
                .font(.system(size: 16))
        default:
            Text("#\(rank)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }

    private var emptyState: some View {
        PlainCard {
            VStack(spacing: 16) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(AdKanTheme.primary.opacity(0.6))

                Text("home.noGroups.title")
                    .font(AdKanTheme.cardTitle)

                Text("home.noGroups.body")
                    .font(AdKanTheme.cardBody)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                NavigationLink {
                    CreateGroupView()
                } label: {
                    Text("home.noGroups.cta")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AdKanTheme.primaryGradient)
                        .clipShape(RoundedRectangle(cornerRadius: AdKanTheme.buttonCornerRadius))
                }
            }
        }
    }
}
