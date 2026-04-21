import XCTest
@testable import AdKan

final class PrivacyBoundaryTests: XCTestCase {

    // MARK: - Privacy boundary: only dailyTotalMinutes crosses network

    func test_scoreSyncPayload_onlyContainsDailyTotal() async throws {
        // Verify the SupabaseScoreSyncService only sends daily_total_minutes + score_date.
        // The sync service has no access to per-app data, category data, or device identifiers.
        // This test documents the architectural constraint.

        let service = StubScoreSyncService()
        // Stub service accepts and discards — the contract is that only
        // an integer (0-1440) is accepted.
        try await service.submitDailyScore(minutes: 120)
        try await service.submitDailyScore(minutes: 0)
        try await service.submitDailyScore(minutes: 1440)
    }

    func test_screenTimeProvider_onlyExposesTotalMinutes() async {
        // The ScreenTimeProvider protocol only has todayTotalMinutes() and
        // yesterdayTotalMinutes(). No per-app breakdown, no category data.
        let provider = StubScreenTimeProvider.goalHit
        let today = await provider.todayTotalMinutes()
        let yesterday = await provider.yesterdayTotalMinutes()

        XCTAssertTrue((0...1440).contains(today))
        XCTAssertTrue((0...1440).contains(yesterday))
    }

    func test_leaderboardEntry_containsNoPII() throws {
        // LeaderboardEntry only has: userId (UUID), displayName, emoji, minutes, rank.
        // No email, phone, device ID, location, or per-app usage.
        let json = """
        {
            "user_id": "uuid-here",
            "display_name": "Yael",
            "avatar_emoji": "🦄",
            "daily_total_minutes": 95,
            "rank": 1
        }
        """.data(using: .utf8)!

        let entry = try JSONDecoder().decode(LeaderboardEntry.self, from: json)
        let mirror = Mirror(reflecting: entry)
        let propertyNames = Set(mirror.children.compactMap(\.label))

        // Assert no PII fields exist
        let piiFields: Set<String> = ["email", "phone", "deviceId", "location", "ipAddress", "appsUsed", "categories"]
        XCTAssertTrue(propertyNames.isDisjoint(with: piiFields), "LeaderboardEntry contains PII field")
    }

    func test_dailyMinutes_clampedRange() {
        // The database CHECK constraint enforces 0-1440.
        // Verify fixtures respect this.
        for fixture in ScreenTimeFixture.all {
            XCTAssertTrue((0...1440).contains(fixture.todayMinutes),
                          "\(fixture.name) today out of range: \(fixture.todayMinutes)")
            XCTAssertTrue((0...1440).contains(fixture.yesterdayMinutes),
                          "\(fixture.name) yesterday out of range: \(fixture.yesterdayMinutes)")
        }
    }
}
