import DeviceActivity
import SwiftUI

struct TotalScreenTimeReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .totalActivity

    let content: (Int) -> TotalScreenTimeView

    private var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.talhayun.AdKan")
    }

    private var reportFileURL: URL? {
        containerURL?.appendingPathComponent("report-data.plist")
    }

    private func writeReport(_ dict: NSDictionary) {
        guard let url = reportFileURL else { return }
        dict.write(to: url, atomically: true)
    }

    func makeConfiguration(
        representing data: DeviceActivityResults<DeviceActivityData>
    ) async -> Int {
        writeReport(["phase": "makeConfig_entered", "startTime": Date().timeIntervalSince1970])

        var totalSeconds: TimeInterval = 0
        var segmentCount = 0

        for await activityData in data {
            for await segment in activityData.activitySegments {
                totalSeconds += segment.totalActivityDuration
                segmentCount += 1
            }
        }

        let totalMinutes = Int(totalSeconds / 60)

        writeReport([
            "todayMinutes": totalMinutes,
            "segmentCount": segmentCount,
            "lastRun": Date().timeIntervalSince1970,
            "phase": "makeConfig_done"
        ])

        return totalMinutes
    }
}

struct TotalScreenTimeView: View {
    let totalMinutes: Int

    var body: some View {
        Text("ST: \(totalMinutes)m")
            .font(.caption2)
            .foregroundStyle(.secondary)
    }
}

extension DeviceActivityReport.Context {
    static let totalActivity = Self("totalActivity")
}
