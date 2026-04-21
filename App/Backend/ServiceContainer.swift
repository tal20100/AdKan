import SwiftUI

final class ServiceContainer: ObservableObject {
    let auth: AuthService
    let scoreSync: ScoreSyncService
    let leaderboard: LeaderboardService

    init() {
        if SupabaseConfig.isConfigured,
           let url = SupabaseConfig.projectURL,
           let key = SupabaseConfig.anonKey {
            let authService = SupabaseAuthService(baseURL: url, apiKey: key)
            self.auth = authService
            self.scoreSync = SupabaseScoreSyncService(
                baseURL: url,
                apiKey: key,
                accessToken: { await authService.accessToken() }
            )
            self.leaderboard = SupabaseLeaderboardService(
                baseURL: url,
                apiKey: key,
                accessToken: { await authService.accessToken() }
            )
        } else {
            self.auth = StubAuthService()
            self.scoreSync = StubScoreSyncService()
            self.leaderboard = StubLeaderboardService()
        }
    }
}

private struct ServiceContainerKey: EnvironmentKey {
    static let defaultValue = ServiceContainer()
}

extension EnvironmentValues {
    var services: ServiceContainer {
        get { self[ServiceContainerKey.self] }
        set { self[ServiceContainerKey.self] = newValue }
    }
}
