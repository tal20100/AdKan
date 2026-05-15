import ManagedSettings
import ManagedSettingsUI
import Foundation

class AdKanShieldActionExtension: ShieldActionDelegate {

    private let store = ManagedSettingsStore()
    private var defaults: UserDefaults? {
        UserDefaults(suiteName: "group.com.talhayun.AdKan")
    }

    func handle(
        action: ShieldAction,
        for application: Application,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        handleAction(action, completionHandler: completionHandler)
    }

    func handle(
        action: ShieldAction,
        for webDomain: WebDomain,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        handleAction(action, completionHandler: completionHandler)
    }

    private func handleAction(
        _ action: ShieldAction,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        switch action {
        case .primaryButtonPressed:
            completionHandler(.close)
        case .secondaryButtonPressed:
            store.shield.applications = nil
            store.shield.applicationCategories = nil
            let reapplyAt = Date().addingTimeInterval(60)
            defaults?.set(reapplyAt.timeIntervalSince1970, forKey: "shield.tempAllowUntil")
            completionHandler(.close)
        @unknown default:
            completionHandler(.close)
        }
    }
}
