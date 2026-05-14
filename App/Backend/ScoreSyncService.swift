import Foundation

protocol ScoreSyncService: Sendable {
    func submitDailyScore(minutes: Int) async throws
    func fetchTodayScore() async throws -> Int?
    func fetchWeeklyScore(for date: Date) async throws -> Int?
}

struct SupabaseScoreSyncService: ScoreSyncService, @unchecked Sendable {
    let baseURL: String
    let apiKey: String
    let accessToken: () async -> String?

    func submitDailyScore(minutes: Int) async throws {
        guard minutes >= 0, minutes <= 1440 else { return }
        guard let token = await accessToken() else { return }

        let url = URL(string: baseURL)!.appendingPathComponent("rest/v1/daily_scores")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        request.setValue("resolution=merge-duplicates", forHTTPHeaderField: "Prefer")
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "daily_total_minutes": minutes,
            "score_date": ISO8601DateFormatter.dateOnly.string(from: Date())
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw SyncError.uploadFailed
        }
    }

    func fetchTodayScore() async throws -> Int? {
        guard let token = await accessToken() else { return nil }

        let today = ISO8601DateFormatter.dateOnly.string(from: Date())
        let base = URL(string: baseURL)!
        var components = URLComponents(url: base.appendingPathComponent("rest/v1/daily_scores"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "score_date", value: "eq.\(today)"),
            URLQueryItem(name: "select", value: "daily_total_minutes"),
            URLQueryItem(name: "limit", value: "1")
        ]

        var request = URLRequest(url: components.url!)
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request)
        let rows = try JSONDecoder().decode([[String: Int]].self, from: data)
        return rows.first?["daily_total_minutes"]
    }

    func fetchWeeklyScore(for date: Date) async throws -> Int? {
        guard let token = await accessToken() else { return nil }

        let dateStr = ISO8601DateFormatter.dateOnly.string(from: date)
        let base = URL(string: baseURL)!
        var components = URLComponents(url: base.appendingPathComponent("rest/v1/daily_scores"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "score_date", value: "eq.\(dateStr)"),
            URLQueryItem(name: "select", value: "daily_total_minutes"),
            URLQueryItem(name: "limit", value: "1")
        ]

        var request = URLRequest(url: components.url!)
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request)
        let rows = try JSONDecoder().decode([[String: Int]].self, from: data)
        return rows.first?["daily_total_minutes"]
    }
}

struct StubScoreSyncService: ScoreSyncService {
    func submitDailyScore(minutes: Int) async throws {}
    func fetchTodayScore() async throws -> Int? { nil }
    func fetchWeeklyScore(for date: Date) async throws -> Int? {
        Int.random(in: 60...180)
    }
}

enum SyncError: Error {
    case uploadFailed
    case notAuthenticated
}

enum LocalScoreStore {
    private static let defaults = UserDefaults.standard

    static func save(minutes: Int, for date: Date) {
        defaults.set(minutes, forKey: key(for: date))
    }

    static func load(for date: Date) -> Int? {
        let k = key(for: date)
        guard defaults.object(forKey: k) != nil else { return nil }
        return defaults.integer(forKey: k)
    }

    private static func key(for date: Date) -> String {
        "localScore_\(ISO8601DateFormatter.dateOnly.string(from: date))"
    }
}

extension ISO8601DateFormatter {
    static let dateOnly: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withFullDate]
        return f
    }()
}
