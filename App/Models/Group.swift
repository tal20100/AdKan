import Foundation

struct AdKanGroup: Identifiable, Codable, Sendable {
    let id: String
    var name: String
    var type: GroupType
    var isFavorite: Bool
    var members: [GroupMember]

    var memberCount: Int { members.count }

    static let freeMaxMembers = 3
    static let paidMaxMembers = 30
}

struct GroupMember: Identifiable, Codable, Sendable {
    let userId: String
    var displayName: String
    var avatarEmoji: String
    var dailyTotalMinutes: Int?
    var rank: Int?

    var id: String { userId }
}

enum GroupType: String, Codable, CaseIterable, Sendable {
    case friends
    case roommates
    case partner
    case coworkers

    var nameKey: String {
        "groups.type.\(rawValue)"
    }

    var emoji: String {
        switch self {
        case .friends: return "👫"
        case .roommates: return "🏠"
        case .partner: return "💑"
        case .coworkers: return "💼"
        }
    }

    var inviteToneKey: String {
        "groups.invite.\(rawValue)"
    }
}
