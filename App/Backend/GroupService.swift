import Foundation

protocol GroupService: Sendable {
    func fetchMyGroups() async throws -> [AdKanGroup]
    func createGroup(name: String, type: GroupType) async throws -> AdKanGroup
    func fetchGroupDetail(groupId: String) async throws -> AdKanGroup
    func addMember(groupId: String, userId: String) async throws
    func removeMember(groupId: String, userId: String) async throws
    func setFavorite(groupId: String, isFavorite: Bool) async throws
}

struct StubGroupService: GroupService {
    func fetchMyGroups() async throws -> [AdKanGroup] {
        [
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
    }

    func createGroup(name: String, type: GroupType) async throws -> AdKanGroup {
        AdKanGroup(id: UUID().uuidString, name: name, type: type, isFavorite: false, members: [])
    }

    func fetchGroupDetail(groupId: String) async throws -> AdKanGroup {
        let groups = try await fetchMyGroups()
        return groups.first { $0.id == groupId } ?? groups[0]
    }

    func addMember(groupId: String, userId: String) async throws {}
    func removeMember(groupId: String, userId: String) async throws {}
    func setFavorite(groupId: String, isFavorite: Bool) async throws {}
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
