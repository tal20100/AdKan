import Foundation

struct TimeBlockRule: Codable, Identifiable {
    let id: UUID
    var appIDs: [String]
    var startHour: Int
    var startMinute: Int
    var endHour: Int
    var endMinute: Int
    var isEnabled: Bool
    var label: String

    init(id: UUID = UUID(), appIDs: [String] = [], startHour: Int = 22, startMinute: Int = 0, endHour: Int = 8, endMinute: Int = 0, isEnabled: Bool = true, label: String = "") {
        self.id = id
        self.appIDs = appIDs
        self.startHour = startHour
        self.startMinute = startMinute
        self.endHour = endHour
        self.endMinute = endMinute
        self.isEnabled = isEnabled
        self.label = label
    }

    var startTimeString: String {
        String(format: "%02d:%02d", startHour, startMinute)
    }

    var endTimeString: String {
        String(format: "%02d:%02d", endHour, endMinute)
    }
}

struct DayScheduleRule: Codable, Identifiable {
    let id: UUID
    var name: String
    var activeDays: Set<Int>
    var defaultLimitMinutes: Int
    var appOverrides: [String: Int]
    var isEnabled: Bool

    init(id: UUID = UUID(), name: String, activeDays: Set<Int>, defaultLimitMinutes: Int, appOverrides: [String: Int] = [:], isEnabled: Bool = false) {
        self.id = id
        self.name = name
        self.activeDays = activeDays
        self.defaultLimitMinutes = defaultLimitMinutes
        self.appOverrides = appOverrides
        self.isEnabled = isEnabled
    }

    static let weekFocus = DayScheduleRule(
        name: "blocking.schedule.weekFocus",
        activeDays: [2, 3, 4, 5, 6],
        defaultLimitMinutes: 60
    )

    static let weekendRelaxed = DayScheduleRule(
        name: "blocking.schedule.weekendRelaxed",
        activeDays: [1, 7],
        defaultLimitMinutes: 180
    )
}

struct GlobalLimitRule: Codable {
    var thresholdMinutes: Int
    var affectedAppIDs: [String]
    var isEnabled: Bool

    init(thresholdMinutes: Int = 180, affectedAppIDs: [String] = [], isEnabled: Bool = false) {
        self.thresholdMinutes = thresholdMinutes
        self.affectedAppIDs = affectedAppIDs
        self.isEnabled = isEnabled
    }
}
