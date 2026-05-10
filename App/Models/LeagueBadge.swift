import Foundation

enum LeagueBadge: String, CaseIterable, Codable, Sendable {
    case none = ""
    case bronze = "🥉"
    case silver = "🥈"
    case gold = "🥇"
    case diamond = "💎"
    case crown = "👑"

    static func from(daysUnderGoal: Int, consecutivePerfectWeeks: Int = 0) -> LeagueBadge {
        if consecutivePerfectWeeks >= 4 { return .crown }
        switch daysUnderGoal {
        case 7: return .diamond
        case 5...6: return .gold
        case 3...4: return .silver
        case 1...2: return .bronze
        default: return .none
        }
    }

    var emoji: String { rawValue }

    var displayable: Bool { self != .none }
}
