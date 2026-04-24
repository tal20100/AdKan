import Foundation
import FamilyControls
import DeviceActivity

/// Real ScreenTime provider using FamilyControls.
/// Usage data is read from the app group shared UserDefaults where a
/// DeviceActivityMonitor extension writes daily totals. Until that
/// extension is built, values default to 0 and the app falls back
/// gracefully (showing "put the phone down" zero-state).
final class RealScreenTimeProvider: ScreenTimeProvider, @unchecked Sendable {
    private let center = AuthorizationCenter.shared
    private let sharedDefaults = UserDefaults(suiteName: "group.com.taltalhayun.adkan")

    var authorizationStatus: AuthorizationStatus {
        get async {
            switch center.authorizationStatus {
            case .approved: return .approved
            case .denied: return .denied
            default: return .notDetermined
            }
        }
    }

    func requestAuthorization() async throws {
        try await center.requestAuthorization(for: .individual)
    }

    func todayTotalMinutes() async -> Int {
        sharedDefaults?.integer(forKey: "todayTotalMinutes") ?? 0
    }

    func yesterdayTotalMinutes() async -> Int {
        sharedDefaults?.integer(forKey: "yesterdayTotalMinutes") ?? 0
    }

    func isPermissionStillGranted() async -> Bool {
        await authorizationStatus == .approved
    }
}
