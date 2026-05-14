import Foundation

struct AdKanGroup: Identifiable, Codable, Sendable {
    let id: String
    var name: String
    var type: GroupType
    var isFavorite: Bool
    var createdBy: String?
    var members: [GroupMember]

    var memberCount: Int { members.count }
}

struct GroupMember: Identifiable, Codable, Sendable {
    let userId: String
    var displayName: String
    var avatarEmoji: String
    var dailyTotalMinutes: Int?
    var currentStreak: Int?
    var leagueBadge: String?
    var rank: Int?
    var isCurrentUser: Bool = false

    var id: String { userId }

    var badge: LeagueBadge {
        LeagueBadge(rawValue: leagueBadge ?? "") ?? .none
    }
}

enum GroupType: String, Codable, CaseIterable, Sendable {
    case friends
    case family
    case roommates
    case partner
    case coworkers

    var nameKey: String {
        "groups.type.\(rawValue)"
    }

    var emoji: String {
        switch self {
        case .friends: return "👫"
        case .family: return "👨‍👩‍👧‍👦"
        case .roommates: return "🏠"
        case .partner: return "💑"
        case .coworkers: return "💼"
        }
    }

    var inviteToneKey: String {
        "groups.invite.\(rawValue)"
    }
}
