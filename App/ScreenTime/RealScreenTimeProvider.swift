import Foundation

#if canImport(FamilyControls)
import FamilyControls
import DeviceActivity

final class RealScreenTimeProvider: ScreenTimeProvider, @unchecked Sendable {
    private let center = AuthorizationCenter.shared

    private var reportData: NSDictionary? {
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.talhayun.AdKan")?
            .appendingPathComponent("report-data.plist") else { return nil }
        return NSDictionary(contentsOf: url)
    }

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
        reportData?["todayMinutes"] as? Int ?? 0
    }

    var reportExtensionLastRan: Date? {
        guard let ts = reportData?["lastRun"] as? Double, ts > 0 else { return nil }
        return Date(timeIntervalSince1970: ts)
    }

    func yesterdayTotalMinutes() async -> Int {
        reportData?["yesterdayMinutes"] as? Int ?? 0
    }

    func isPermissionStillGranted() async -> Bool {
        await authorizationStatus == .approved
    }
}
#endif
