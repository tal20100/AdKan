import Foundation

protocol GroupService: Sendable {
    func fetchMyGroups() async throws -> [AdKanGroup]
    func createGroup(name: String, type: GroupType) async throws -> AdKanGroup
    func fetchGroupDetail(groupId: String) async throws -> AdKanGroup
    func addMember(groupId: String, userId: String) async throws
    func removeMember(groupId: String, userId: String) async throws
    func setFavorite(groupId: String, isFavorite: Bool) async throws
    func renameGroup(groupId: String, newName: String) async throws
    func leaveGroup(groupId: String) async throws
}

final class StubGroupService: GroupService, @unchecked Sendable {
    private var storedGroups: [AdKanGroup] = [
        AdKanGroup(
            id: "group-1",
            name: "חברים",
            type: .friends,
            isFavorite: true,
            createdBy: "stub-user-id",
            members: [
                GroupMember(userId: "stub-user-id", displayName: "You", avatarEmoji: "😎", dailyTotalMinutes: 95, currentStreak: 5, leagueBadge: "🥇", rank: 1, isCurrentUser: true),
                GroupMember(userId: "user-2", displayName: "יעל", avatarEmoji: "🌸", dailyTotalMinutes: 140, currentStreak: 3, leagueBadge: "🥈", rank: 2),
                GroupMember(userId: "user-3", displayName: "עומר", avatarEmoji: "🔥", dailyTotalMinutes: 185, currentStreak: 0, leagueBadge: "", rank: 3),
                GroupMember(userId: "user-4", displayName: "נועה", avatarEmoji: "🌺", dailyTotalMinutes: 210, currentStreak: 1, leagueBadge: "🥉", rank: 4)
            ]
        ),
        AdKanGroup(
            id: "group-2",
            name: "עבודה",
            type: .coworkers,
            isFavorite: false,
            createdBy: "stub-user-id",
            members: [
                GroupMember(userId: "stub-user-id", displayName: "You", avatarEmoji: "😎", dailyTotalMinutes: 95, currentStreak: 5, leagueBadge: "🥇", rank: 1, isCurrentUser: true)
            ]
        )
    ]

    func fetchMyGroups() async throws -> [AdKanGroup] {
        storedGroups
    }

    func createGroup(name: String, type: GroupType) async throws -> AdKanGroup {
        let me = GroupMember(userId: "stub-user-id", displayName: "You", avatarEmoji: "😎", dailyTotalMinutes: 0, currentStreak: 0, leagueBadge: "", rank: 1, isCurrentUser: true)
        let group = AdKanGroup(id: UUID().uuidString, name: name, type: type, isFavorite: false, createdBy: "stub-user-id", members: [me])
        storedGroups.append(group)
        return group
    }

    func fetchGroupDetail(groupId: String) async throws -> AdKanGroup {
        storedGroups.first { $0.id == groupId } ?? storedGroups[0]
    }

    func addMember(groupId: String, userId: String) async throws {
        guard let idx = storedGroups.firstIndex(where: { $0.id == groupId }) else { return }
        let member = GroupMember(userId: userId, displayName: "Friend", avatarEmoji: "🙂", dailyTotalMinutes: nil, currentStreak: 0, leagueBadge: "", rank: nil)
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

    func renameGroup(groupId: String, newName: String) async throws {
        guard let idx = storedGroups.firstIndex(where: { $0.id == groupId }) else { return }
        storedGroups[idx].name = newName
    }

    func leaveGroup(groupId: String) async throws {
        storedGroups.removeAll { $0.id == groupId }
    }
}

struct SupabaseGroupService: GroupService {
    let baseURL: String
    let apiKey: String
    let accessToken: @Sendable () async -> String?

    private func authHeaders() async -> [(String, String)] {
        var headers = [
            ("Content-Type", "application/json"),
            ("apikey", apiKey)
        ]
        if let token = await accessToken() {
            headers.append(("Authorization", "Bearer \(token)"))
        }
        return headers
    }

    private func applyHeaders(_ request: inout URLRequest, headers: [(String, String)]) {
        for (key, value) in headers { request.setValue(value, forHTTPHeaderField: key) }
    }

    func fetchMyGroups() async throws -> [AdKanGroup] {
        guard await accessToken() != nil else { return [] }
        let headers = await authHeaders()

        let url = URL(string: baseURL)!.appendingPathComponent("rest/v1/rpc/my_groups")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        applyHeaders(&request, headers: headers)
        request.httpBody = try JSONSerialization.data(withJSONObject: [:] as [String: String])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            return []
        }
        return try JSONDecoder().decode([AdKanGroup].self, from: data)
    }

    func createGroup(name: String, type: GroupType) async throws -> AdKanGroup {
        let headers = await authHeaders()

        let url = URL(string: baseURL)!.appendingPathComponent("rest/v1/rpc/create_group")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        applyHeaders(&request, headers: headers)
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")

        let body: [String: String] = ["group_name": name, "group_type": type.rawValue]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            let message = String(data: data, encoding: .utf8) ?? ""
            if message.contains("Group limit reached") {
                throw GroupServiceError.groupLimitReached
            }
            throw GroupServiceError.requestFailed
        }
        return try JSONDecoder().decode(AdKanGroup.self, from: data)
    }

    func fetchGroupDetail(groupId: String) async throws -> AdKanGroup {
        let headers = await authHeaders()

        let url = URL(string: baseURL)!.appendingPathComponent("rest/v1/rpc/group_detail")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        applyHeaders(&request, headers: headers)

        let body = ["group_id": groupId]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw GroupServiceError.requestFailed
        }
        return try JSONDecoder().decode(AdKanGroup.self, from: data)
    }

    func addMember(groupId: String, userId: String) async throws {
        let headers = await authHeaders()

        let url = URL(string: baseURL)!.appendingPathComponent("rest/v1/rpc/add_member")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        applyHeaders(&request, headers: headers)

        let body: [String: String] = ["target_group_id": groupId, "target_user_id": userId]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            let message = String(data: data, encoding: .utf8) ?? ""
            if message.contains("Premium required") {
                throw GroupServiceError.premiumRequired
            } else if message.contains("Group is full") {
                throw GroupServiceError.groupFull
            }
            throw GroupServiceError.requestFailed
        }
    }

    func removeMember(groupId: String, userId: String) async throws {
        let headers = await authHeaders()

        let base = URL(string: baseURL)!
        var components = URLComponents(url: base.appendingPathComponent("rest/v1/group_members"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "group_id", value: "eq.\(groupId)"),
            URLQueryItem(name: "user_id", value: "eq.\(userId)")
        ]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "DELETE"
        applyHeaders(&request, headers: headers)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw GroupServiceError.requestFailed
        }
    }

    func setFavorite(groupId: String, isFavorite: Bool) async throws {
        let headers = await authHeaders()

        let url = URL(string: baseURL)!.appendingPathComponent("rest/v1/rpc/set_favorite_group")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        applyHeaders(&request, headers: headers)

        let body: [String: Any] = ["target_group_id": groupId, "is_favorite": isFavorite]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw GroupServiceError.requestFailed
        }
    }

    func renameGroup(groupId: String, newName: String) async throws {
        let headers = await authHeaders()

        let base = URL(string: baseURL)!
        var components = URLComponents(url: base.appendingPathComponent("rest/v1/groups"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "id", value: "eq.\(groupId)")]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "PATCH"
        applyHeaders(&request, headers: headers)

        let body = ["name": newName]
        request.httpBody = try JSONEncoder().encode(body)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw GroupServiceError.requestFailed
        }
    }

    func leaveGroup(groupId: String) async throws {
        let headers = await authHeaders()

        let url = URL(string: baseURL)!.appendingPathComponent("rest/v1/rpc/leave_group")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        applyHeaders(&request, headers: headers)

        let body: [String: String] = ["target_group_id": groupId]
        request.httpBody = try JSONEncoder().encode(body)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw GroupServiceError.requestFailed
        }
    }
}

enum GroupServiceError: Error, LocalizedError {
    case requestFailed
    case notAuthenticated
    case premiumRequired
    case groupFull
    case groupLimitReached

    var errorDescription: String? {
        switch self {
        case .requestFailed: return "Group service request failed."
        case .notAuthenticated: return "Not authenticated."
        case .premiumRequired: return "Premium subscription required."
        case .groupFull: return "This group is full."
        case .groupLimitReached: return "Group limit reached."
        }
    }
}
