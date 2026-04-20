import SwiftUI

@main
struct AdKanApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @StateObject private var router = Router()

    var body: some Scene {
        WindowGroup {
            RootView(hasCompletedOnboarding: $hasCompletedOnboarding)
                .environmentObject(router)
                .environment(\.screenTimeProvider, StubScreenTimeProvider.goalHit)
                .environment(\.layoutDirection, Locale.current.language.languageCode?.identifier == "he" ? .rightToLeft : .leftToRight)
        }
    }
}
