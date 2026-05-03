import Foundation

#if canImport(FamilyControls)
import FamilyControls
import DeviceActivity

final class RealScreenTimeProvider: ScreenTimeProvider, @unchecked Sendable {
    private let center = AuthorizationCenter.shared
    private let sharedDefaults = UserDefaults(suiteName: "group.com.talhayun.AdKan")

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
#endif
