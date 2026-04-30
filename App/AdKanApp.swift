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

    var body: some Scene {
        WindowGroup {
            RootView(hasCompletedOnboarding: $hasCompletedOnboarding)
                .environmentObject(router)
                .environmentObject(services)
                .environmentObject(languageManager)
                .environmentObject(storeManager)
                .environmentObject(streakTracker)
                .environmentObject(blockingRuleStore)
                .environment(\.screenTimeProvider, Self.makeScreenTimeProvider())
                .environment(\.locale, languageManager.locale)
                .environment(\.layoutDirection, languageManager.layoutDirection)
                .id(languageManager.preferredLanguage)
                .task {
                    await NotificationManager.shared.checkStatus()
                }
        }
    }

    private static func makeScreenTimeProvider() -> any ScreenTimeProvider {
        // RealScreenTimeProvider is excluded from build until the paid
        // Apple Developer account + FamilyControls entitlement are active.
        // Re-add it in project.yml sources and swap this back when ready.
        return StubScreenTimeProvider.goalHit
    }
}
