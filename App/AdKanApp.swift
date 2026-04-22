import SwiftUI

@main
struct AdKanApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @StateObject private var router = Router()
    @StateObject private var services = ServiceContainer()
    @StateObject private var languageManager = LanguageManager()

    var body: some Scene {
        WindowGroup {
            RootView(hasCompletedOnboarding: $hasCompletedOnboarding)
                .environmentObject(router)
                .environmentObject(services)
                .environmentObject(languageManager)
                .environment(\.screenTimeProvider, StubScreenTimeProvider.goalHit)
                .environment(\.locale, languageManager.locale)
                .environment(\.layoutDirection, languageManager.layoutDirection)
        }
    }
}
