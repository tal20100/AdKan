import DeviceActivity
import FamilyControls
import ManagedSettings
import Foundation

class AdKanDeviceActivityMonitorExtension: DeviceActivityMonitor {

    private let store = ManagedSettingsStore()

    private var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.talhayun.AdKan")
    }

    private var reportData: NSDictionary? {
        guard let url = containerURL?.appendingPathComponent("report-data.plist") else { return nil }
        return NSDictionary(contentsOf: url)
    }

    private func writeReport(_ dict: NSDictionary) {
        guard let url = containerURL?.appendingPathComponent("report-data.plist") else { return }
        dict.write(to: url, atomically: true)
    }

    override func intervalDidStart(for activity: DeviceActivityName) {
        let todayMinutes = reportData?["todayMinutes"] as? Int ?? 0
        var updated = (reportData as? [String: Any]) ?? [:]
        if todayMinutes > 0 {
            updated["yesterdayMinutes"] = todayMinutes
        }
        updated["todayMinutes"] = 0
        writeReport(updated as NSDictionary)

        reapplyIfTempAllowExpired()
        applyShieldsFromSavedTokens()
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
    }

    override func eventDidReachThreshold(
        _ event: DeviceActivityEvent.Name,
        activity: DeviceActivityName
    ) {
        reapplyIfTempAllowExpired()
        applyShieldsFromSavedTokens()
    }

    private func reapplyIfTempAllowExpired() {
        guard let url = containerURL?.appendingPathComponent("shield-config.plist"),
              let dict = NSDictionary(contentsOf: url),
              let ts = dict["tempAllowUntil"] as? Double, ts > 0 else { return }
        if Date().timeIntervalSince1970 >= ts {
            let updated = (dict as? [String: Any] ?? [:]).filter { $0.key != "tempAllowUntil" }
            (updated as NSDictionary).write(to: url, atomically: true)
            applyShieldsFromSavedTokens()
        }
    }

    private func applyShieldsFromSavedTokens() {
        guard let url = containerURL?.appendingPathComponent("shield-tokens.bin"),
              let data = try? Data(contentsOf: url) else { return }

        do {
            let selection = try JSONDecoder().decode(FamilyActivitySelection.self, from: data)
            let apps = selection.applicationTokens
            let categories = selection.categoryTokens

            if !apps.isEmpty {
                store.shield.applications = apps
            }
            if !categories.isEmpty {
                store.shield.applicationCategories = .specific(categories)
            }
        } catch {}
    }
}

extension DeviceActivityName {
    static let dailySchedule = Self("com.talhayun.AdKan.dailySchedule")
}

extension DeviceActivityEvent.Name {
    static let usageThresholdReached = Self("com.talhayun.AdKan.usageThreshold")
}
