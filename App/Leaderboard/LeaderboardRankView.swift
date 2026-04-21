import SwiftUI

struct LeaderboardRankView: View {
    @EnvironmentObject private var services: ServiceContainer
    @Environment(\.screenTimeProvider) private var provider
    @State private var entries: [LeaderboardEntry] = []
    @State private var todayMinutes: Int = 0
    @AppStorage("dailyGoalMinutes") private var goalMinutes: Int = 120

    private var savedMinutes: Int {
        max(0, (24 * 60) - todayMinutes)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AdKanTheme.cardSpacing) {
                    if entries.isEmpty {
                        myRankCard
                        emptyFriendsCard
                    } else {
                        ForEach(entries) { entry in
                            leaderboardRow(entry)
                        }
                    }
                }
                .padding(.horizontal, AdKanTheme.screenPadding)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(Text("tab.leaderboard"))
            .task {
                todayMinutes = await provider.todayTotalMinutes()
                entries = (try? await services.leaderboard.fetchLeaderboard(for: Date())) ?? []
            }
            .refreshable {
                entries = (try? await services.leaderboard.fetchLeaderboard(for: Date())) ?? []
            }
        }
    }

    private func leaderboardRow(_ entry: LeaderboardEntry) -> some View {
        let isMe = entry.userId == services.auth.currentUserId || entry.userId == "me"
        let saved = max(0, 1440 - entry.dailyTotalMinutes)

        return PlainCard {
            HStack(spacing: 16) {
                Text("\(entry.rank)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(entry.rank <= 3 ? AdKanTheme.primary : .secondary)
                    .frame(width: 36)

                Text(entry.avatarEmoji)
                    .font(.title)

                VStack(alignment: .leading, spacing: 4) {
                    Text(isMe ? String(localized: "leaderboard.you") : entry.displayName)
                        .font(.headline)
                    Text("\(saved)m saved")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if saved >= goalMinutes {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(AdKanTheme.successGreen)
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: AdKanTheme.cardCornerRadius)
                .stroke(isMe ? AdKanTheme.primary.opacity(0.4) : .clear, lineWidth: 2)
        )
    }

    private var myRankCard: some View {
        PlainCard {
            HStack(spacing: 16) {
                Text("1")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(AdKanTheme.primary)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text("leaderboard.you")
                        .font(.headline)
                    Text("\(savedMinutes)m saved")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: savedMinutes >= goalMinutes ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(savedMinutes >= goalMinutes ? AdKanTheme.successGreen : Color(.systemGray3))
            }
        }
    }

    private var emptyFriendsCard: some View {
        PlainCard {
            VStack(spacing: 16) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(AdKanTheme.primary.opacity(0.6))

                Text("leaderboard.empty.body")
                    .font(AdKanTheme.cardBody)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                AdKanButton(titleKey: "leaderboard.empty.cta", style: .primary) {
                    shareInviteLink()
                }
            }
        }
    }

    private func shareInviteLink() {
        let text = NSLocalizedString("invite.shareText", comment: "")
        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.keyWindow?.rootViewController {
            root.present(av, animated: true)
        }
    }
}
