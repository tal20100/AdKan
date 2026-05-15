import ManagedSettings
import ManagedSettingsUI
import Foundation

class AdKanShieldActionExtension: ShieldActionDelegate {

    private let store = ManagedSettingsStore()
    private var defaults: UserDefaults? {
        UserDefaults(suiteName: "group.com.talhayun.AdKan")
    }

    override func handle(
        action: ShieldAction,
        for application: ApplicationToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        handleAction(action, completionHandler: completionHandler)
    }

    override func handle(
        action: ShieldAction,
        for webDomain: WebDomainToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        handleAction(action, completionHandler: completionHandler)
    }

    override func handle(
        action: ShieldAction,
        for category: ActivityCategoryToken,
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
            defaults?.set(Date().addingTimeInterval(60).timeIntervalSince1970, forKey: "shield.tempAllowUntil")
            completionHandler(.close)
        @unknown default:
            completionHandler(.close)
        }
    }
}
