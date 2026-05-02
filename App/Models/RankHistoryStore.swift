// [SKILL-DECL] Consulted plan/status.md and App/Backend/LeaderboardService.swift for UserDefaults patterns
import Foundation

final class RankHistoryStore {
    static let shared = RankHistoryStore()
    private init() {}

    // Save today's ranks for a group: [userId → rank]
    func saveRanks(_ ranks: [String: Int], groupId: String, date: Date = Date()) {
        let k = storageKey(groupId: groupId, date: date)
        UserDefaults.standard.set(ranks, forKey: k)
    }

    // Look up a user's rank from yesterday for the given group.
    func previousRank(for userId: String, groupId: String) -> Int? {
        guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) else { return nil }
        let k = storageKey(groupId: groupId, date: yesterday)
        let stored = UserDefaults.standard.dictionary(forKey: k) as? [String: Int]
        return stored?[userId]
    }

    private func storageKey(groupId: String, date: Date) -> String {
        "rankHistory_\(groupId)_\(ISO8601DateFormatter.dateOnly.string(from: date))"
    }
}
