import SwiftUI

struct RootView: View {
    @Binding var hasCompletedOnboarding: Bool
    @EnvironmentObject private var router: Router

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView(onComplete: {
                    hasCompletedOnboarding = true
                })
            }
        }
        .animation(.easeInOut, value: hasCompletedOnboarding)
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            LeaderboardView()
                .tabItem {
                    Label {
                        Text("tab.home")
                    } icon: {
                        Image(systemName: "house.fill")
                    }
                }

            LeaderboardRankView()
                .tabItem {
                    Label {
                        Text("tab.leaderboard")
                    } icon: {
                        Image(systemName: "trophy.fill")
                    }
                }

            SettingsView()
                .tabItem {
                    Label {
                        Text("tab.settings")
                    } icon: {
                        Image(systemName: "gearshape.fill")
                    }
                }
        }
        .tint(Color.accentColor)
    }
}
