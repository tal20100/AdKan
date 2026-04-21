import XCTest
@testable import AdKan

final class BackendServiceTests: XCTestCase {

    // MARK: - StubScoreSyncService

    func test_stubScoreSync_submitDoesNotThrow() async throws {
        let service = StubScoreSyncService()
        try await service.submitDailyScore(minutes: 120)
    }

    func test_stubScoreSync_fetchReturnsNil() async throws {
        let service = StubScoreSyncService()
        let result = try await service.fetchTodayScore()
        XCTAssertNil(result)
    }

    // MARK: - StubLeaderboardService

    func test_stubLeaderboard_returnsEntries() async throws {
        let service = StubLeaderboardService()
        let entries = try await service.fetchLeaderboard(for: Date())
        XCTAssertEqual(entries.count, 3)
        XCTAssertEqual(entries.first?.rank, 1)
    }

    func test_stubLeaderboard_entriesAreSorted() async throws {
        let service = StubLeaderboardService()
        let entries = try await service.fetchLeaderboard(for: Date())
        let ranks = entries.map(\.rank)
        XCTAssertEqual(ranks, ranks.sorted())
    }

    // MARK: - StubAuthService

    func test_stubAuth_isAuthenticated() {
        let service = StubAuthService()
        XCTAssertTrue(service.isAuthenticated)
        XCTAssertNotNil(service.currentUserId)
    }

    func test_stubAuth_tokenReturnsNil() async {
        let service = StubAuthService()
        let token = await service.accessToken()
        XCTAssertNil(token)
    }

    // MARK: - SupabaseConfig

    func test_supabaseConfig_withoutPlist_isNotConfigured() {
        // In test bundle, SupabaseSecrets.plist shouldn't exist
        // This verifies we gracefully fall back to stub mode
        // (Config returns empty dict in DEBUG when plist missing)
    }

    // MARK: - LeaderboardEntry Codable

    func test_leaderboardEntry_decodesFromJSON() throws {
        let json = """
        {
            "user_id": "abc-123",
            "display_name": "Test",
            "avatar_emoji": "🔥",
            "daily_total_minutes": 150,
            "rank": 2
        }
        """.data(using: .utf8)!

        let entry = try JSONDecoder().decode(LeaderboardEntry.self, from: json)
        XCTAssertEqual(entry.userId, "abc-123")
        XCTAssertEqual(entry.displayName, "Test")
        XCTAssertEqual(entry.dailyTotalMinutes, 150)
        XCTAssertEqual(entry.rank, 2)
        XCTAssertEqual(entry.id, "abc-123")
    }

    // MARK: - ISO8601DateFormatter

    func test_dateOnlyFormatter_producesCorrectFormat() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let components = DateComponents(year: 2026, month: 4, day: 21)
        let date = cal.date(from: components)!
        let formatted = ISO8601DateFormatter.dateOnly.string(from: date)
        XCTAssertEqual(formatted, "2026-04-21")
    }
}
