import Foundation
import Security

enum KeychainScreenTimeStore {
    private static let service = "com.talhayun.AdKan.screentime"
    private static let accessGroup = "group.com.talhayun.AdKan"
    private static let todayKey = "todayMinutes"
    private static let lastRunKey = "lastRunTimestamp"

    static var todayMinutes: Int {
        get { readInt(key: todayKey) ?? 0 }
        set { writeInt(key: todayKey, value: newValue) }
    }

    static var lastRunTimestamp: Double {
        get { readDouble(key: lastRunKey) ?? 0 }
        set { writeDouble(key: lastRunKey, value: newValue) }
    }

    private static func readInt(key: String) -> Int? {
        guard let data = readData(key: key),
              data.count == MemoryLayout<Int>.size else { return nil }
        return data.withUnsafeBytes { $0.load(as: Int.self) }
    }

    private static func writeInt(key: String, value: Int) {
        var v = value
        let data = Data(bytes: &v, count: MemoryLayout<Int>.size)
        writeData(key: key, data: data)
    }

    private static func readDouble(key: String) -> Double? {
        guard let data = readData(key: key),
              data.count == MemoryLayout<Double>.size else { return nil }
        return data.withUnsafeBytes { $0.load(as: Double.self) }
    }

    private static func writeDouble(key: String, value: Double) {
        var v = value
        let data = Data(bytes: &v, count: MemoryLayout<Double>.size)
        writeData(key: key, data: data)
    }

    private static func readData(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecAttrAccessGroup as String: accessGroup,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }

    private static func writeData(key: String, data: Data) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecAttrAccessGroup as String: accessGroup
        ]
        let attrs: [String: Any] = [kSecValueData as String: data]

        let status = SecItemUpdate(query as CFDictionary, attrs as CFDictionary)
        if status == errSecItemNotFound {
            var newItem = query
            newItem[kSecValueData as String] = data
            newItem[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
            SecItemAdd(newItem as CFDictionary, nil)
        }
    }
}
