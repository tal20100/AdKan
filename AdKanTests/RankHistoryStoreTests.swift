import XCTest
@testable import AdKan

final class RankHistoryStoreTests: XCTestCase {

    private let store = RankHistoryStore.shared
    private let groupA = "group-test-a"
    private let groupB = "group-test-b"

    override func setUp() {
        super.setUp()
        // Clear any leftover test data from yesterday's key
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let key = "rankHistory_\(groupA)_\(ISO8601DateFormatter.dateOnly.string(from: yesterday))"
        UserDefaults.standard.removeObject(forKey: key)
        let keyB = "rankHistory_\(groupB)_\(ISO8601DateFormatter.dateOnly.string(from: yesterday))"
        UserDefaults.standard.removeObject(forKey: keyB)
    }

    func test_previousRank_returnsNil_whenNoHistoryStored() {
        let rank = store.previousRank(for: "user-1", groupId: "group-no-history")
        XCTAssertNil(rank)
    }

    func test_saveRanks_thenPreviousRank_returnsCorrectRank() {
        // Save ranks as if they were from yesterday
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        store.saveRanks(["user-1": 2, "user-2": 1], groupId: groupA, date: yesterday)

        XCTAssertEqual(store.previousRank(for: "user-1", groupId: groupA), 2)
        XCTAssertEqual(store.previousRank(for: "user-2", groupId: groupA), 1)
    }

    func test_previousRank_returnsNil_forUnknownUser() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        store.saveRanks(["user-1": 3], groupId: groupA, date: yesterday)

        XCTAssertNil(store.previousRank(for: "user-unknown", groupId: groupA))
    }

    func test_previousRank_isIsolatedByGroup() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        store.saveRanks(["user-1": 1], groupId: groupA, date: yesterday)
        store.saveRanks(["user-1": 5], groupId: groupB, date: yesterday)

        XCTAssertEqual(store.previousRank(for: "user-1", groupId: groupA), 1)
        XCTAssertEqual(store.previousRank(for: "user-1", groupId: groupB), 5)
    }

    func test_todayRanks_doNotAppearAsPreviousRank() {
        // Saving today's ranks should NOT affect previousRank (which looks at yesterday)
        store.saveRanks(["user-1": 4], groupId: groupA, date: Date())

        XCTAssertNil(store.previousRank(for: "user-1", groupId: groupA))
    }
}
