import SwiftUI

@main
struct AdKanApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @StateObject private var router = Router()
    @StateObject private var services = ServiceContainer()
    @StateObject private var languageManager = LanguageManager()
    @StateObject private var storeManager = StoreManager()

    var body: some Scene {
        WindowGroup {
            RootView(hasCompletedOnboarding: $hasCompletedOnboarding)
                .environmentObject(router)
                .environmentObject(services)
                .environmentObject(languageManager)
                .environmentObject(storeManager)
                .environment(\.screenTimeProvider, Self.makeScreenTimeProvider())
                .environment(\.locale, languageManager.locale)
                .environment(\.layoutDirection, languageManager.layoutDirection)
                .id(languageManager.preferredLanguage)
        }
    }

    private static func makeScreenTimeProvider() -> any ScreenTimeProvider {
        #if targetEnvironment(simulator)
        return StubScreenTimeProvider.goalHit
        #else
        return RealScreenTimeProvider()
        #endif
    }
}
