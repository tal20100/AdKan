import Foundation

enum SupabaseConfig {
    static var isConfigured: Bool {
        !SupabaseSecrets.url.isEmpty && !SupabaseSecrets.anonKey.isEmpty
    }

    static var projectURL: URL? {
        guard isConfigured else { return nil }
        return URL(string: SupabaseSecrets.url)
    }

    static var anonKey: String? {
        guard isConfigured else { return nil }
        return SupabaseSecrets.anonKey
    }
}
