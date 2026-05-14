import Foundation

#if canImport(ManagedSettings) && canImport(FamilyControls)
import ManagedSettings
import FamilyControls

@MainActor
final class BlockingEnforcer: ObservableObject {
    static let shared = BlockingEnforcer()

    private let store = ManagedSettingsStore()
    private var reapplyTask: Task<Void, Never>?

    func applyShields(for selection: FamilyActivitySelection) {
        let apps = selection.applicationTokens
        let categories = selection.categoryTokens

        store.shield.applications = apps.isEmpty ? nil : apps
        store.shield.applicationCategories = categories.isEmpty
            ? nil
            : ShieldSettings.ActivityCategoryPolicy.specific(categories)

        if let data = try? JSONEncoder().encode(selection) {
            SharedDefaults.blockedAppTokensData = data
        }
    }

    func removeAllShields() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.clearAllSettings()
    }

    func allowTemporarily(minutes: Int = 1) {
        let savedTokens = SharedDefaults.blockedAppTokensData
        store.shield.applications = nil
        store.shield.applicationCategories = nil

        let defaults = UserDefaults(suiteName: "group.com.talhayun.AdKan")
        let reapplyAt = Date().addingTimeInterval(Double(minutes * 60))
        defaults?.set(reapplyAt.timeIntervalSince1970, forKey: "shield.tempAllowUntil")

        reapplyTask?.cancel()
        reapplyTask = Task {
            try? await Task.sleep(for: .seconds(minutes * 60))
            guard !Task.isCancelled else { return }
            defaults?.removeObject(forKey: "shield.tempAllowUntil")
            if let data = savedTokens,
               let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
                applyShields(for: selection)
            }
        }
    }

    func reapplyIfTempAllowExpired() {
        let defaults = UserDefaults(suiteName: "group.com.talhayun.AdKan")
        guard let ts = defaults?.double(forKey: "shield.tempAllowUntil"), ts > 0 else { return }
        if Date().timeIntervalSince1970 >= ts {
            defaults?.removeObject(forKey: "shield.tempAllowUntil")
            if let selection = loadSavedSelection() {
                applyShields(for: selection)
            }
        }
    }

    func loadSavedSelection() -> FamilyActivitySelection? {
        guard let data = SharedDefaults.blockedAppTokensData else { return nil }
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
