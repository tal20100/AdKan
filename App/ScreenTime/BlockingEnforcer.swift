import Foundation

#if canImport(ManagedSettings) && canImport(FamilyControls)
import ManagedSettings
import FamilyControls
import DeviceActivity

extension DeviceActivityName {
    static let dailySchedule = Self("com.talhayun.AdKan.dailySchedule")
}

@MainActor
final class BlockingEnforcer: ObservableObject {
    static let shared = BlockingEnforcer()

    private let store = ManagedSettingsStore()
    private var reapplyTask: Task<Void, Never>?

    private var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.talhayun.AdKan")
    }

    func applyShields(for selection: FamilyActivitySelection) {
        let apps = selection.applicationTokens
        let categories = selection.categoryTokens

        store.shield.applications = apps.isEmpty ? nil : apps
        store.shield.applicationCategories = categories.isEmpty
            ? nil
            : ShieldSettings.ActivityCategoryPolicy.specific(categories)

        if let data = try? JSONEncoder().encode(selection),
           let url = containerURL?.appendingPathComponent("shield-tokens.bin") {
            try? data.write(to: url, options: .atomic)
        }

        startDailyMonitoring()
    }

    func startDailyMonitoring() {
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59, second: 59),
            repeats: true
        )
        var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]
        for minutes in stride(from: 15, through: 480, by: 15) {
            let name = DeviceActivityEvent.Name("com.talhayun.AdKan.threshold.\(minutes)")
            events[name] = DeviceActivityEvent(threshold: DateComponents(minute: minutes))
        }
        let center = DeviceActivityCenter()
        center.stopMonitoring([.dailySchedule])
        try? center.startMonitoring(.dailySchedule, during: schedule, events: events)
    }

    func removeAllShields() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.clearAllSettings()
    }

    func allowTemporarily(minutes: Int = 1) {
        let savedTokens = loadSavedTokensData()
        store.shield.applications = nil
        store.shield.applicationCategories = nil

        let reapplyAt = Date().addingTimeInterval(Double(minutes * 60))
        if let url = containerURL?.appendingPathComponent("shield-config.plist") {
            let dict: NSDictionary = ["tempAllowUntil": reapplyAt.timeIntervalSince1970]
            dict.write(to: url, atomically: true)
        }

        reapplyTask?.cancel()
        reapplyTask = Task {
            try? await Task.sleep(for: .seconds(minutes * 60))
            guard !Task.isCancelled else { return }
            if let url = containerURL?.appendingPathComponent("shield-config.plist") {
                try? FileManager.default.removeItem(at: url)
            }
            if let data = savedTokens,
               let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
                applyShields(for: selection)
            }
        }
    }

    func reapplyIfTempAllowExpired() {
        guard let url = containerURL?.appendingPathComponent("shield-config.plist"),
              let dict = NSDictionary(contentsOf: url),
              let ts = dict["tempAllowUntil"] as? Double, ts > 0 else { return }
        if Date().timeIntervalSince1970 >= ts {
            try? FileManager.default.removeItem(at: url)
            if let selection = loadSavedSelection() {
                applyShields(for: selection)
            }
        }
    }

    private func loadSavedTokensData() -> Data? {
        guard let url = containerURL?.appendingPathComponent("shield-tokens.bin") else { return nil }
        return try? Data(contentsOf: url)
    }

    func loadSavedSelection() -> FamilyActivitySelection? {
        guard let data = loadSavedTokensData() else { return nil }
        return try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
    }
}

#else

@MainActor
final class BlockingEnforcer: ObservableObject {
    static let shared = BlockingEnforcer()
    func removeAllShields() {}
    func reapplyIfTempAllowExpired() {}
}

#endif
