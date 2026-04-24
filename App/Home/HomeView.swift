import SwiftUI

struct HomeView: View {
    @Environment(\.screenTimeProvider) private var provider
    @EnvironmentObject private var services: ServiceContainer
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
                        TimeReclaimedView(savedMinutes: savedMinutes, goalMinutes: goalMinutes)

                        usageCard

                        ProgressBarView(currentMinutes: todayMinutes, goalMinutes: goalMinutes, compact: false)

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
            .task {
                todayMinutes = await provider.todayTotalMinutes()
                yesterdayMinutes = await provider.yesterdayTotalMinutes()
                do {
                    groups = try await services.groups.fetchMyGroups()
                } catch {
                    loadError = error.localizedDescription
                }
                isLoading = false
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
