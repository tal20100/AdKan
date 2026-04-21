import SwiftUI

@main
struct AdKanApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @StateObject private var router = Router()
    @StateObject private var services = ServiceContainer()

    var body: some Scene {
        WindowGroup {
            RootView(hasCompletedOnboarding: $hasCompletedOnboarding)
                .environmentObject(router)
                .environmentObject(services)
                .environment(\.screenTimeProvider, StubScreenTimeProvider.goalHit)
                .environment(\.layoutDirection, Locale.current.language.languageCode?.identifier == "he" ? .rightToLeft : .leftToRight)
        }
    }
}
