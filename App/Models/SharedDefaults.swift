// [SKILL-DECL] Consulted App/Models/StreakTracker.swift and App/Home/HomeView.swift for data patterns
import Foundation

/// UserDefaults shared between the main app and the widget via App Groups.
/// The App Group ID must be registered at developer.apple.com before data will flow.
struct SharedDefaults {
    static let suiteName = "group.com.talhayun.AdKan"
    private static let suite = UserDefaults(suiteName: suiteName) ?? .standard

    static var todayMinutes: Int {
        get { suite.integer(forKey: "widget.todayMinutes") }
        set { suite.set(newValue, forKey: "widget.todayMinutes") }
    }

    static var goalMinutes: Int {
        get {
            let v = suite.integer(forKey: "widget.goalMinutes")
            return v > 0 ? v : 120
        }
        set { suite.set(newValue, forKey: "widget.goalMinutes") }
    }

    static var currentStreak: Int {
        get { suite.integer(forKey: "widget.currentStreak") }
        set { suite.set(newValue, forKey: "widget.currentStreak") }
    }

    static var yesterdayMinutes: Int {
        get { suite.integer(forKey: "widget.yesterdayMinutes") }
        set { suite.set(newValue, forKey: "widget.yesterdayMinutes") }
    }

    // MARK: - Shield Configuration (read by ShieldConfigurationExtension)

    static var shieldTitle: String {
        get { suite.string(forKey: "shield.title") ?? "עד כאן" }
        set { suite.set(newValue, forKey: "shield.title") }
    }

    static var shieldSubtitle: String {
        get { suite.string(forKey: "shield.subtitle") ?? "You chose to limit this app. Stay strong!" }
        set { suite.set(newValue, forKey: "shield.subtitle") }
    }

    static var shieldPrimaryButton: String {
        get { suite.string(forKey: "shield.primaryButton") ?? "Close" }
        set { suite.set(newValue, forKey: "shield.primaryButton") }
    }

    static var shieldSecondaryButton: String {
        get { suite.string(forKey: "shield.secondaryButton") ?? "Allow 1 min" }
        set { suite.set(newValue, forKey: "shield.secondaryButton") }
    }

    static var shieldIsPremium: Bool {
        get { suite.bool(forKey: "shield.isPremium") }
        set { suite.set(newValue, forKey: "shield.isPremium") }
    }

    static var shieldThemeIndex: Int {
        get { suite.integer(forKey: "shield.themeIndex") }
        set { suite.set(newValue, forKey: "shield.themeIndex") }
    }

    static var blockedAppTokensData: Data? {
        get { suite.data(forKey: "shield.blockedTokens") }
        set { suite.set(newValue, forKey: "shield.blockedTokens") }
    }
}
