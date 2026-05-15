import Foundation
import AuthenticationServices

protocol AuthService: Sendable {
    var currentUserId: String? { get }
    var isAuthenticated: Bool { get }
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws
    func signOut()
    func accessToken() async -> String?
    func updateProfile(displayName: String, avatarEmoji: String) async throws
    func ensureUserRow() async throws
}

final class SupabaseAuthService: AuthService, @unchecked Sendable {
    private let baseURL: String
    private let apiKey: String
    private let tokenKey = "com.talhayun.AdKan.accessToken"
    private let userIdKey = "com.talhayun.AdKan.userId"

    init(baseURL: String, apiKey: String) {
        self.baseURL = baseURL
        self.apiKey = apiKey
    }

    var currentUserId: String? {
        UserDefaults.standard.string(forKey: userIdKey)
    }

    var isAuthenticated: Bool {
        currentUserId != nil && KeychainHelper.read(key: tokenKey) != nil
    }

    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws {
        guard let identityToken = credential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            throw AuthError.missingToken
        }

        let url = URL(string: baseURL)!.appendingPathComponent("auth/v1/token")
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "grant_type", value: "id_token")]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "apikey")

        let body: [String: Any] = [
            "provider": "apple",
            "id_token": tokenString
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw AuthError.serverError
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let token = json["access_token"] as? String,
              let user = json["user"] as? [String: Any],
              let userId = user["id"] as? String else {
            throw AuthError.invalidResponse
        }

        KeychainHelper.save(key: tokenKey, value: token)
        UserDefaults.standard.set(userId, forKey: userIdKey)

        try await ensureUserRow()
    }

    func signOut() {
        KeychainHelper.delete(key: tokenKey)
        UserDefaults.standard.removeObject(forKey: userIdKey)
    }

    func accessToken() async -> String? {
        KeychainHelper.read(key: tokenKey)
    }

    func updateProfile(displayName: String, avatarEmoji: String) async throws {
        guard let token = KeychainHelper.read(key: tokenKey) else { return }

        let url = URL(string: baseURL)!.appendingPathComponent("rest/v1/rpc/update_profile")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let body: [String: String] = [
            "new_display_name": displayName,
            "new_avatar_emoji": avatarEmoji
        ]
        request.httpBody = try JSONEncoder().encode(body)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw AuthError.serverError
        }
    }

    func ensureUserRow() async throws {
        guard let token = KeychainHelper.read(key: tokenKey) else { return }

        let url = URL(string: baseURL)!.appendingPathComponent("rest/v1/rpc/ensure_user")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        var body: [String: String] = [:]
        if let name = UserDefaults.standard.string(forKey: "profileDisplayName"), !name.isEmpty {
            body["p_display_name"] = name
        }
        if let emoji = UserDefaults.standard.string(forKey: "profileAvatarEmoji"), !emoji.isEmpty {
            body["p_avatar_emoji"] = emoji
        }
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AuthError.serverError
        }
    }
}

struct StubAuthService: AuthService {
    var currentUserId: String? { "stub-user-id" }
    var isAuthenticated: Bool { true }
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws {}
    func signOut() {}
    func accessToken() async -> String? { nil }
    func updateProfile(displayName: String, avatarEmoji: String) async throws {}
    func ensureUserRow() async throws {}
}

enum AuthError: Error, LocalizedError {
    case missingToken
    case serverError
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .missingToken: return "Apple Sign-In did not provide a token."
        case .serverError: return "Authentication server error."
        case .invalidResponse: return "Unexpected server response."
        }
    }
}
