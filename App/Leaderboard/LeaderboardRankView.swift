import SwiftUI

struct LeaderboardRankView: View {
    @Environment(\.screenTimeProvider) private var provider
    @State private var todayMinutes: Int = 0
    @AppStorage("dailyGoalMinutes") private var goalMinutes: Int = 120

    private var savedMinutes: Int {
        max(0, (24 * 60) - todayMinutes)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AdKanTheme.cardSpacing) {
                    myRankCard

                    friendsSection
                }
                .padding(.horizontal, AdKanTheme.screenPadding)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(Text("tab.leaderboard"))
            .task {
                todayMinutes = await provider.todayTotalMinutes()
            }
        }
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
                    Text("\(savedMinutes) min saved")
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

    private var friendsSection: some View {
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
