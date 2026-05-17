import DeviceActivity
import SwiftUI
import Security

struct TotalScreenTimeReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .totalActivity

    let content: (Int) -> TotalScreenTimeView

    func makeConfiguration(
        representing data: DeviceActivityResults<DeviceActivityData>
    ) async -> Int {
        var totalSeconds: TimeInterval = 0

        for await activityData in data {
            for await segment in activityData.activitySegments {
                totalSeconds += segment.totalActivityDuration
            }
        }

        let totalMinutes = Int(totalSeconds / 60)

        Self.writeToKeychain(minutes: totalMinutes)

        return totalMinutes
    }

    private static let keychainService = "com.talhayun.AdKan.screentime"
    private static let keychainGroup = "group.com.talhayun.AdKan"

    private static func writeToKeychain(minutes: Int) {
        writeKeychainInt(key: "todayMinutes", value: minutes)
        var ts = Date().timeIntervalSince1970
        let tsData = Data(bytes: &ts, count: MemoryLayout<Double>.size)
        writeKeychainData(key: "lastRunTimestamp", data: tsData)
    }

    private static func writeKeychainInt(key: String, value: Int) {
        var v = value
        let data = Data(bytes: &v, count: MemoryLayout<Int>.size)
        writeKeychainData(key: key, data: data)
    }

    private static func writeKeychainData(key: String, data: Data) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecAttrAccessGroup as String: keychainGroup
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

struct TotalScreenTimeView: View {
    let totalMinutes: Int

    private var hours: Int { totalMinutes / 60 }
    private var mins: Int { totalMinutes % 60 }

    private var isHebrew: Bool {
        Locale.current.language.languageCode?.identifier.hasPrefix("he") == true
    }

    private var timeText: String {
        if hours > 0 && mins > 0 {
            return isHebrew
                ? "\(hours) שע׳ ו-\(mins) דק׳"
                : "\(hours)h \(mins)m"
        } else if hours > 0 {
            return isHebrew ? "\(hours) שעות" : "\(hours)h"
        } else {
            return isHebrew ? "\(mins) דקות" : "\(mins)m"
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            Text(timeText)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .foregroundStyle(.primary)

            Text(isHebrew ? "זמן מסך היום" : "Screen time today")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}

extension DeviceActivityReport.Context {
    static let totalActivity = Self("totalActivity")
}
