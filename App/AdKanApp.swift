import SwiftUI

@main
struct AdKanApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @StateObject private var router = Router()
    @StateObject private var services = ServiceContainer()
    @StateObject private var languageManager = LanguageManager()
    @StateObject private var storeManager = StoreManager()
    @StateObject private var streakTracker = StreakTracker()
    @StateObject private var blockingRuleStore = BlockingRuleStore()
    @StateObject private var appearanceManager = AppearanceManager()

    var body: some Scene {
        WindowGroup {
            RootView(hasCompletedOnboarding: $hasCompletedOnboarding)
                .environmentObject(router)
                .environmentObject(services)
                .environmentObject(languageManager)
                .environmentObject(storeManager)
                .environmentObject(streakTracker)
                .environmentObject(blockingRuleStore)
                .environmentObject(appearanceManager)
                .environment(\.screenTimeProvider, Self.makeScreenTimeProvider())
                .preferredColorScheme(appearanceManager.colorScheme)
                .environment(\.locale, languageManager.locale)
                .environment(\.layoutDirection, languageManager.layoutDirection)
                .id(languageManager.preferredLanguage)
                .onOpenURL { url in
                    guard url.scheme == "adkan", url.host == "join" else { return }
                    let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
                    guard let groupId = components?.queryItems?.first(where: { $0.name == "group" })?.value else { return }
                    router.navigate(to: .groupDetail(groupId: groupId))
                }
                .task {
                    await NotificationManager.shared.checkStatus()
                    if UserDefaults.standard.object(forKey: "inactivityReminderEnabled") as? Bool ?? true {
                        NotificationManager.shared.scheduleInactivityReengagement(
                            groupName: nil,
                            lastRank: nil,
                            streak: 0
                        )
                    }
                }
        }
    }

    private static func makeScreenTimeProvider() -> any ScreenTimeProvider {
        #if canImport(FamilyControls) && !targetEnvironment(simulator)
        return RealScreenTimeProvider()
        #else
        return StubScreenTimeProvider.goalHit
        #endif
    }
}
