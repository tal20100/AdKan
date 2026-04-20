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
                        Text("leaderboard.empty.title")
                    } icon: {
                        Image(systemName: "chart.bar.fill")
                    }
                }

            SettingsView()
                .tabItem {
                    Label {
                        Text("settings.title")
                    } icon: {
                        Image(systemName: "gearshape.fill")
                    }
                }
        }
        .tint(Color.accentColor)
    }
}
