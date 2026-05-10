import Foundation

struct LeaderboardEntry: Identifiable, Codable, Sendable {
    let userId: String
    let displayName: String
    let avatarEmoji: String
    let dailyTotalMinutes: Int
    let currentStreak: Int
    let leagueBadge: String
    let rank: Int

    var id: String { userId }

    var badge: LeagueBadge {
        LeagueBadge(rawValue: leagueBadge) ?? .none
    }

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case displayName = "display_name"
        case avatarEmoji = "avatar_emoji"
        case dailyTotalMinutes = "daily_total_minutes"
        case currentStreak = "current_streak"
        case leagueBadge = "league_badge"
        case rank
    }
}

struct WeeklyLeaderboardEntry: Identifiable, Codable, Sendable {
    let userId: String
    let displayName: String
    let avatarEmoji: String
    let weeklyTotalMinutes: Int
    let currentStreak: Int
    let leagueBadge: String
    let rank: Int

    var id: String { userId }

    var badge: LeagueBadge {
        LeagueBadge(rawValue: leagueBadge) ?? .none
    }

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case displayName = "display_name"
        case avatarEmoji = "avatar_emoji"
        case weeklyTotalMinutes = "weekly_total_minutes"
        case currentStreak = "current_streak"
        case leagueBadge = "league_badge"
        case rank
    }
}

protocol LeaderboardService: Sendable {
    func fetchLeaderboard(for date: Date) async throws -> [LeaderboardEntry]
    func fetchWeeklyLeaderboard(weekStart: Date?) async throws -> [WeeklyLeaderboardEntry]
}

struct SupabaseLeaderboardService: LeaderboardService, @unchecked Sendable {
    let baseURL: String
    let apiKey: String
    let accessToken: () async -> String?

    private func makeRequest(rpc: String, body: [String: String]) async throws -> Data? {
        guard let token = await accessToken() else { return nil }
        let url = URL(string: baseURL)!.appendingPathComponent("rest/v1/rpc/\(rpc)")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            return nil
        }
        return data
    }

    func fetchLeaderboard(for date: Date) async throws -> [LeaderboardEntry] {
        let dateStr = ISO8601DateFormatter.dateOnly.string(from: date)
        guard let data = try await makeRequest(rpc: "leaderboard_for", body: ["target_date": dateStr]) else {
            return []
        }
        return try JSONDecoder().decode([LeaderboardEntry].self, from: data)
    }

    func fetchWeeklyLeaderboard(weekStart: Date? = nil) async throws -> [WeeklyLeaderboardEntry] {
        var body: [String: String] = [:]
        if let weekStart {
            body["week_start"] = ISO8601DateFormatter.dateOnly.string(from: weekStart)
        }
        guard let data = try await makeRequest(rpc: "weekly_leaderboard_for", body: body) else {
            return []
        }
        return try JSONDecoder().decode([WeeklyLeaderboardEntry].self, from: data)
    }
}

struct StubLeaderboardService: LeaderboardService {
    func fetchLeaderboard(for date: Date) async throws -> [LeaderboardEntry] {
        [
            LeaderboardEntry(userId: "me", displayName: "You", avatarEmoji: "😊", dailyTotalMinutes: 95, currentStreak: 5, leagueBadge: "🥇", rank: 1),
            LeaderboardEntry(userId: "f1", displayName: "Yael", avatarEmoji: "🦄", dailyTotalMinutes: 120, currentStreak: 3, leagueBadge: "🥈", rank: 2),
            LeaderboardEntry(userId: "f2", displayName: "Omer", avatarEmoji: "🔥", dailyTotalMinutes: 185, currentStreak: 0, leagueBadge: "", rank: 3),
            LeaderboardEntry(userId: "f3", displayName: "Noa", avatarEmoji: "🌺", dailyTotalMinutes: 210, currentStreak: 1, leagueBadge: "🥉", rank: 4),
        ]
    }

    func fetchWeeklyLeaderboard(weekStart: Date? = nil) async throws -> [WeeklyLeaderboardEntry] {
        [
            WeeklyLeaderboardEntry(userId: "me", displayName: "You", avatarEmoji: "😊", weeklyTotalMinutes: 630, currentStreak: 5, leagueBadge: "🥇", rank: 1),
            WeeklyLeaderboardEntry(userId: "f1", displayName: "Yael", avatarEmoji: "🦄", weeklyTotalMinutes: 840, currentStreak: 3, leagueBadge: "🥈", rank: 2),
            WeeklyLeaderboardEntry(userId: "f2", displayName: "Omer", avatarEmoji: "🔥", weeklyTotalMinutes: 1120, currentStreak: 0, leagueBadge: "", rank: 3),
            WeeklyLeaderboardEntry(userId: "f3", displayName: "Noa", avatarEmoji: "🌺", weeklyTotalMinutes: 1350, currentStreak: 1, leagueBadge: "🥉", rank: 4),
        ]
    }
}
