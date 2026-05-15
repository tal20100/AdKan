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

    enum CodingKeys: String, CodingKey {
        case userId, displayName, avatarEmoji, dailyTotalMinutes
        case currentStreak, leagueBadge, rank, isCurrentUser
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        userId = try c.decode(String.self, forKey: .userId)
        displayName = try c.decodeIfPresent(String.self, forKey: .displayName) ?? ""
        avatarEmoji = try c.decodeIfPresent(String.self, forKey: .avatarEmoji) ?? ""
        dailyTotalMinutes = try c.decodeIfPresent(Int.self, forKey: .dailyTotalMinutes)
        currentStreak = try c.decodeIfPresent(Int.self, forKey: .currentStreak)
        leagueBadge = try c.decodeIfPresent(String.self, forKey: .leagueBadge)
        rank = try c.decodeIfPresent(Int.self, forKey: .rank)
        isCurrentUser = try c.decodeIfPresent(Bool.self, forKey: .isCurrentUser) ?? false
    }

    init(userId: String, displayName: String, avatarEmoji: String, dailyTotalMinutes: Int? = nil, currentStreak: Int? = nil, leagueBadge: String? = nil, rank: Int? = nil, isCurrentUser: Bool = false) {
        self.userId = userId
        self.displayName = displayName
        self.avatarEmoji = avatarEmoji
        self.dailyTotalMinutes = dailyTotalMinutes
        self.currentStreak = currentStreak
        self.leagueBadge = leagueBadge
        self.rank = rank
        self.isCurrentUser = isCurrentUser
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
