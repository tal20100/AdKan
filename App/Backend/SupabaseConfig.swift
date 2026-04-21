import Foundation

enum SupabaseConfig {
    private static let config: [String: String] = {
        guard let url = Bundle.main.url(forResource: "SupabaseSecrets", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String] else {
            #if DEBUG
            print("[AdKan] SupabaseSecrets.plist not found — running in offline/stub mode.")
            return [:]
            #else
            fatalError("SupabaseSecrets.plist missing from bundle. See config/SupabaseSecrets.plist.example.")
            #endif
        }
        return dict
    }()

    static var isConfigured: Bool {
        !config.isEmpty
    }

    static var projectURL: URL? {
        config["SUPABASE_URL"].flatMap(URL.init(string:))
    }

    static var anonKey: String? {
        config["SUPABASE_ANON_KEY"]
    }
}
