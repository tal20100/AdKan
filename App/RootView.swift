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
            HomeView()
                .tabItem {
                    Label {
                        Text("tab.home")
                    } icon: {
                        Image(systemName: "house.fill")
                    }
                }

            GroupsListView()
                .tabItem {
                    Label {
                        Text("tab.groups")
                    } icon: {
                        Image(systemName: "trophy.fill")
                    }
                }

            BlockingView()
                .tabItem {
                    Label {
                        Text("tab.blocking")
                    } icon: {
                        Image(systemName: "shield.checkered")
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
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}
