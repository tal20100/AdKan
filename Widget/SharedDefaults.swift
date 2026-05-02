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
}
