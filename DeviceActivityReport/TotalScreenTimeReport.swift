import DeviceActivity
import SwiftUI

struct TotalScreenTimeReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .totalActivity

    let content: (Int) -> TotalScreenTimeView

    private var defaults: UserDefaults? {
        UserDefaults(suiteName: "group.com.talhayun.AdKan")
    }

    func makeConfiguration(
        representing data: DeviceActivityResults<DeviceActivityData>
    ) async -> Int {
        defaults?.set("makeConfig_entered", forKey: "report.phase")
        defaults?.set(Date().timeIntervalSince1970, forKey: "report.startTime")
        defaults?.set(true, forKey: "report.writeTest")
        defaults?.synchronize()

        var totalSeconds: TimeInterval = 0
        var segmentCount = 0

        for await activityData in data {
            for await segment in activityData.activitySegments {
                totalSeconds += segment.totalActivityDuration
                segmentCount += 1
            }
        }

        let totalMinutes = Int(totalSeconds / 60)

        defaults?.set(totalMinutes, forKey: "widget.todayMinutes")
        defaults?.set(Date().timeIntervalSince1970, forKey: "report.lastRun")
        defaults?.set(segmentCount, forKey: "report.segmentCount")
        defaults?.set("makeConfig_done", forKey: "report.phase")
        defaults?.synchronize()

        return totalMinutes
    }
}

struct TotalScreenTimeView: View {
    let totalMinutes: Int

    var body: some View {
        let defaults = UserDefaults(suiteName: "group.com.talhayun.AdKan")
        let defaultsOK = defaults != nil
        let readBack = defaults?.integer(forKey: "widget.todayMinutes") ?? -1
        let phase = defaults?.string(forKey: "report.phase") ?? "nil"

        VStack(alignment: .leading, spacing: 2) {
            Text("ST: \(totalMinutes)m")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("UD:\(defaultsOK ? "ok" : "NIL") rb:\(readBack) ph:\(phase)")
                .font(.system(size: 9))
                .foregroundStyle(defaultsOK ? .green : .red)
        }
    }
}

extension TimeInterval {
    var toMinutes: Int {
        Int(self / 60)
    }
}

extension DeviceActivityReport.Context {
    static let totalActivity = Self("totalActivity")
}
