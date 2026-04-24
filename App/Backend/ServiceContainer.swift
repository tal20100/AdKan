import SwiftUI

final class ServiceContainer: ObservableObject {
    let auth: AuthService
    let scoreSync: ScoreSyncService
    let leaderboard: LeaderboardService
    let groups: GroupService

    init() {
        if SupabaseConfig.isConfigured,
           let url = SupabaseConfig.projectURL,
           let key = SupabaseConfig.anonKey {
            let authService = SupabaseAuthService(baseURL: url.absoluteString, apiKey: key)
            self.auth = authService
            self.scoreSync = SupabaseScoreSyncService(
                baseURL: url.absoluteString,
                apiKey: key,
                accessToken: { await authService.accessToken() }
            )
            self.leaderboard = SupabaseLeaderboardService(
                baseURL: url.absoluteString,
                apiKey: key,
                accessToken: { await authService.accessToken() }
            )
            self.groups = SupabaseGroupService(
                baseURL: url.absoluteString,
                apiKey: key,
                accessToken: { await authService.accessToken() }
            )
        } else {
            self.auth = StubAuthService()
            self.scoreSync = StubScoreSyncService()
            self.leaderboard = StubLeaderboardService()
            self.groups = StubGroupService()
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
