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
        let keychainValue = KeychainScreenTimeStore.todayMinutes
        if keychainValue > 0 { return keychainValue }

        let fileValue = reportData?["todayMinutes"] as? Int ?? 0
        if fileValue > 0 { return fileValue }

        try? await Task.sleep(for: .seconds(1))
        let retryKeychain = KeychainScreenTimeStore.todayMinutes
        if retryKeychain > 0 { return retryKeychain }

        return reportData?["todayMinutes"] as? Int ?? 0
    }

    var reportExtensionLastRan: Date? {
        let ts = KeychainScreenTimeStore.lastRunTimestamp
        if ts > 0 { return Date(timeIntervalSince1970: ts) }
        guard let fileTs = reportData?["lastRun"] as? Double, fileTs > 0 else { return nil }
        return Date(timeIntervalSince1970: fileTs)
    }

    func yesterdayTotalMinutes() async -> Int {
        reportData?["yesterdayMinutes"] as? Int ?? 0
    }

    func isPermissionStillGranted() async -> Bool {
        await authorizationStatus == .approved
    }
}
#endif
