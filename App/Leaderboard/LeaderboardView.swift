import SwiftUI

struct LeaderboardView: View {
    @Environment(\.screenTimeProvider) private var provider
    @State private var todayMinutes: Int = 0
    @State private var yesterdayMinutes: Int = 0
    @AppStorage("dailyGoalMinutes") private var goalMinutes: Int = 120

    private var savedMinutes: Int {
        max(0, (24 * 60) - todayMinutes)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AdKanTheme.cardSpacing) {
                    TimeReclaimedView(savedMinutes: savedMinutes, goalMinutes: goalMinutes)

                    usageCard

                    friendsSection
                }
                .padding(.horizontal, AdKanTheme.screenPadding)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(Text("app.displayName"))
            .task {
                todayMinutes = await provider.todayTotalMinutes()
                yesterdayMinutes = await provider.yesterdayTotalMinutes()
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

    private var friendsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("leaderboard.empty.title")
                    .font(AdKanTheme.cardTitle)
                Spacer()
            }

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
