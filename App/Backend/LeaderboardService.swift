import Foundation

struct LeaderboardEntry: Identifiable, Codable, Sendable {
    let userId: String
    let displayName: String
    let avatarEmoji: String
    let dailyTotalMinutes: Int
    let rank: Int

    var id: String { userId }

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case displayName = "display_name"
        case avatarEmoji = "avatar_emoji"
        case dailyTotalMinutes = "daily_total_minutes"
        case rank
    }
}

protocol LeaderboardService: Sendable {
    func fetchLeaderboard(for date: Date) async throws -> [LeaderboardEntry]
}

struct SupabaseLeaderboardService: LeaderboardService {
    let baseURL: URL
    let apiKey: String
    let accessToken: () async -> String?

    func fetchLeaderboard(for date: Date) async throws -> [LeaderboardEntry] {
        guard let token = await accessToken() else { return [] }

        let dateStr = ISO8601DateFormatter.dateOnly.string(from: date)
        let url = baseURL.appendingPathComponent("rest/v1/rpc/leaderboard_for")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(["target_date": dateStr])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            return []
        }
        return try JSONDecoder().decode([LeaderboardEntry].self, from: data)
    }
}

struct StubLeaderboardService: LeaderboardService {
    func fetchLeaderboard(for date: Date) async throws -> [LeaderboardEntry] {
        [
            LeaderboardEntry(userId: "me", displayName: "You", avatarEmoji: "😊", dailyTotalMinutes: 95, rank: 1),
            LeaderboardEntry(userId: "f1", displayName: "Yael", avatarEmoji: "🦄", dailyTotalMinutes: 120, rank: 2),
            LeaderboardEntry(userId: "f2", displayName: "Omer", avatarEmoji: "🔥", dailyTotalMinutes: 185, rank: 3),
        ]
    }
}
