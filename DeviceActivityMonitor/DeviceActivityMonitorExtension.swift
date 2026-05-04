import DeviceActivity
import FamilyControls
import ManagedSettings
import Foundation

class AdKanDeviceActivityMonitorExtension: DeviceActivityMonitor {

    private let store = ManagedSettingsStore()

    private var defaults: UserDefaults? {
        UserDefaults(suiteName: "group.com.talhayun.AdKan")
    }

    override func intervalDidStart(for activity: DeviceActivityName) {
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
        applyShieldsFromSavedTokens()
    }

    private func applyShieldsFromSavedTokens() {
        guard let data = defaults?.data(forKey: "shield.blockedTokens") else { return }

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
        } catch {
            // Extension has limited logging — fail silently
        }
    }
}

extension DeviceActivityName {
    static let dailySchedule = Self("com.talhayun.AdKan.dailySchedule")
}

extension DeviceActivityEvent.Name {
    static let usageThresholdReached = Self("com.talhayun.AdKan.usageThreshold")
}
