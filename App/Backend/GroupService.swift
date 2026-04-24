import Foundation

protocol GroupService: Sendable {
    func fetchMyGroups() async throws -> [AdKanGroup]
    func createGroup(name: String, type: GroupType) async throws -> AdKanGroup
    func fetchGroupDetail(groupId: String) async throws -> AdKanGroup
    func addMember(groupId: String, userId: String) async throws
    func removeMember(groupId: String, userId: String) async throws
    func setFavorite(groupId: String, isFavorite: Bool) async throws
}

final class StubGroupService: GroupService, @unchecked Sendable {
    private var storedGroups: [AdKanGroup] = [
        AdKanGroup(
            id: "group-1",
            name: "חברים",
            type: .friends,
            isFavorite: true,
            members: [
                GroupMember(userId: "stub-user-id", displayName: "You", avatarEmoji: "😎", dailyTotalMinutes: 95, rank: 1),
                GroupMember(userId: "user-2", displayName: "יעל", avatarEmoji: "🌸", dailyTotalMinutes: 140, rank: 2)
            ]
        ),
        AdKanGroup(
            id: "group-2",
            name: "עבודה",
            type: .coworkers,
            isFavorite: false,
            members: [
                GroupMember(userId: "stub-user-id", displayName: "You", avatarEmoji: "😎", dailyTotalMinutes: 95, rank: 1)
            ]
        )
    ]

    func fetchMyGroups() async throws -> [AdKanGroup] {
        storedGroups
    }

    func createGroup(name: String, type: GroupType) async throws -> AdKanGroup {
        let me = GroupMember(userId: "stub-user-id", displayName: "You", avatarEmoji: "😎", dailyTotalMinutes: 0, rank: 1)
        let group = AdKanGroup(id: UUID().uuidString, name: name, type: type, isFavorite: false, members: [me])
        storedGroups.append(group)
        return group
    }

    func fetchGroupDetail(groupId: String) async throws -> AdKanGroup {
        storedGroups.first { $0.id == groupId } ?? storedGroups[0]
    }

    func addMember(groupId: String, userId: String) async throws {
        guard let idx = storedGroups.firstIndex(where: { $0.id == groupId }) else { return }
        let member = GroupMember(userId: userId, displayName: "Friend", avatarEmoji: "🙂", dailyTotalMinutes: nil, rank: nil)
        storedGroups[idx].members.append(member)
    }

    func removeMember(groupId: String, userId: String) async throws {
        guard let idx = storedGroups.firstIndex(where: { $0.id == groupId }) else { return }
        storedGroups[idx].members.removeAll { $0.userId == userId }
    }

    func setFavorite(groupId: String, isFavorite: Bool) async throws {
        if isFavorite {
            for i in storedGroups.indices { storedGroups[i].isFavorite = false }
        }
        guard let idx = storedGroups.firstIndex(where: { $0.id == groupId }) else { return }
        storedGroups[idx].isFavorite = isFavorite
    }
}

struct SupabaseGroupService: GroupService {
    let baseURL: String
    let apiKey: String
    let accessToken: @Sendable () async -> String?

    func fetchMyGroups() async throws -> [AdKanGroup] {
        // TODO: Implement Supabase REST call
        return []
    }

    func createGroup(name: String, type: GroupType) async throws -> AdKanGroup {
        // TODO: Implement Supabase REST call
        AdKanGroup(id: UUID().uuidString, name: name, type: type, isFavorite: false, members: [])
    }

    func fetchGroupDetail(groupId: String) async throws -> AdKanGroup {
        // TODO: Implement Supabase REST call
        AdKanGroup(id: groupId, name: "", type: .friends, isFavorite: false, members: [])
    }

    func addMember(groupId: String, userId: String) async throws {
        // TODO: Implement Supabase REST call
    }

    func removeMember(groupId: String, userId: String) async throws {
        // TODO: Implement Supabase REST call
    }

    func setFavorite(groupId: String, isFavorite: Bool) async throws {
        // TODO: Implement Supabase REST call
    }
}
