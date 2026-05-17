import Foundation

/// File-based sharing between the main app and extensions via the App Group container.
/// UserDefaults(suiteName:) does not reliably sync cross-process on device;
/// file I/O through containerURL is the reliable alternative.
struct SharedDefaults {
    static let suiteName = "group.com.talhayun.AdKan"

    private static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: suiteName)
    }

    // MARK: - Report data (written by DeviceActivityReport ext, read by main app)

    private static var reportData: NSDictionary? {
        guard let url = containerURL?.appendingPathComponent("report-data.plist") else { return nil }
        return NSDictionary(contentsOf: url)
    }

    static var todayMinutes: Int {
        get { reportData?["todayMinutes"] as? Int ?? 0 }
        set {
            var dict = (reportData as? [String: Any]) ?? [:]
            dict["todayMinutes"] = newValue
            if let url = containerURL?.appendingPathComponent("report-data.plist") {
                (dict as NSDictionary).write(to: url, atomically: true)
            }
        }
    }

    static var yesterdayMinutes: Int {
        get { reportData?["yesterdayMinutes"] as? Int ?? 0 }
        set {
            var dict = (reportData as? [String: Any]) ?? [:]
            dict["yesterdayMinutes"] = newValue
            if let url = containerURL?.appendingPathComponent("report-data.plist") {
                (dict as NSDictionary).write(to: url, atomically: true)
            }
        }
    }

    // MARK: - Widget data (written by main app, read by widget)

    private static var widgetFileURL: URL? {
        containerURL?.appendingPathComponent("widget-data.plist")
    }

    private static var widgetData: NSDictionary? {
        guard let url = widgetFileURL else { return nil }
        return NSDictionary(contentsOf: url)
    }

    private static func writeWidgetData(_ dict: [String: Any]) {
        guard let url = widgetFileURL else { return }
        (dict as NSDictionary).write(to: url, atomically: true)
    }

    static var goalMinutes: Int {
        get {
            let v = widgetData?["goalMinutes"] as? Int ?? 0
            return v > 0 ? v : 120
        }
        set {
            var dict = (widgetData as? [String: Any]) ?? [:]
            dict["goalMinutes"] = newValue
            writeWidgetData(dict)
        }
    }

    static var currentStreak: Int {
        get { widgetData?["currentStreak"] as? Int ?? 0 }
        set {
            var dict = (widgetData as? [String: Any]) ?? [:]
            dict["currentStreak"] = newValue
            writeWidgetData(dict)
        }
    }

    // MARK: - Shield UI config (written by main app, read by ShieldConfiguration ext)

    private static var shieldUIFileURL: URL? {
        containerURL?.appendingPathComponent("shield-ui.plist")
    }

    private static var shieldUI: NSDictionary? {
        guard let url = shieldUIFileURL else { return nil }
        return NSDictionary(contentsOf: url)
    }

    private static func writeShieldUI(_ dict: [String: Any]) {
        guard let url = shieldUIFileURL else { return }
        (dict as NSDictionary).write(to: url, atomically: true)
    }

    static var shieldTitle: String {
        get { shieldUI?["shield.title"] as? String ?? "עד כאן" }
        set { var d = (shieldUI as? [String: Any]) ?? [:]; d["shield.title"] = newValue; writeShieldUI(d) }
    }

    static var shieldSubtitle: String {
        get { shieldUI?["shield.subtitle"] as? String ?? "You chose to limit this app. Stay strong!" }
        set { var d = (shieldUI as? [String: Any]) ?? [:]; d["shield.subtitle"] = newValue; writeShieldUI(d) }
    }

    static var shieldPrimaryButton: String {
        get { shieldUI?["shield.primaryButton"] as? String ?? "Close" }
        set { var d = (shieldUI as? [String: Any]) ?? [:]; d["shield.primaryButton"] = newValue; writeShieldUI(d) }
    }

    static var shieldSecondaryButton: String {
        get { shieldUI?["shield.secondaryButton"] as? String ?? "Allow 1 min" }
        set { var d = (shieldUI as? [String: Any]) ?? [:]; d["shield.secondaryButton"] = newValue; writeShieldUI(d) }
    }

    static var shieldIsPremium: Bool {
        get { shieldUI?["shield.isPremium"] as? Bool ?? false }
        set { var d = (shieldUI as? [String: Any]) ?? [:]; d["shield.isPremium"] = newValue; writeShieldUI(d) }
    }

    static var shieldThemeIndex: Int {
        get { shieldUI?["shield.themeIndex"] as? Int ?? 0 }
        set { var d = (shieldUI as? [String: Any]) ?? [:]; d["shield.themeIndex"] = newValue; writeShieldUI(d) }
    }

    // MARK: - Blocked tokens (written by main app, read by monitor ext) — handled by BlockingEnforcer via shield-tokens.bin
}
