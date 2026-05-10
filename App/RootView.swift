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
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label {
                        Text("tab.home")
                    } icon: {
                        Image(systemName: "house.fill")
                    }
                }
                .tag(0)

            GroupsListView()
                .tabItem {
                    Label {
                        Text("tab.groups")
                    } icon: {
                        Image(systemName: "trophy.fill")
                    }
                }
                .tag(1)

            BlockingView()
                .tabItem {
                    Label {
                        Text("tab.blocking")
                    } icon: {
                        Image(systemName: "shield.checkered")
                    }
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label {
                        Text("tab.settings")
                    } icon: {
                        Image(systemName: "gearshape.fill")
                    }
                }
                .tag(3)
        }
        .tint(Color.accentColor)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .environment(\.switchToFocusTab, { selectedTab = 2 })
    }
}

private struct SwitchToFocusTabKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

extension EnvironmentValues {
    var switchToFocusTab: () -> Void {
        get { self[SwitchToFocusTabKey.self] }
        set { self[SwitchToFocusTabKey.self] = newValue }
    }
}
