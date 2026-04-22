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
                            Text("#\(member.rank ?? 0)")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(.secondary)
                                .frame(width: 28, alignment: .leading)

                            Text(member.avatarEmoji)
                                .font(.title3)

                            Text(member.displayName)
                                .font(.subheadline.weight(.medium))

                            Spacer()

                            if let minutes = member.dailyTotalMinutes {
                                Text("\(minutes)m")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AdKanTheme.minutesColor(minutes))
                            }
                        }
                    }
                }
            }
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
