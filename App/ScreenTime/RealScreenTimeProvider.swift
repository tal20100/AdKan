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
        for _ in 0..<3 {
            let value = sharedDefaults?.integer(forKey: "widget.todayMinutes") ?? 0
            if value > 0 { return value }
            try? await Task.sleep(for: .seconds(1))
        }
        return sharedDefaults?.integer(forKey: "widget.todayMinutes") ?? 0
    }

    func yesterdayTotalMinutes() async -> Int {
        sharedDefaults?.integer(forKey: "widget.yesterdayMinutes") ?? 0
    }

    func isPermissionStillGranted() async -> Bool {
        await authorizationStatus == .approved
    }
}
#endif
