import DeviceActivity
import SwiftUI

@available(iOS 16.1, *)
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

        let defaults = UserDefaults(suiteName: "group.com.talhayun.AdKan")
        defaults?.set(totalMinutes, forKey: "widget.todayMinutes")
        defaults?.set(Date().timeIntervalSince1970, forKey: "report.lastRun")
        defaults?.synchronize()

        return totalMinutes
    }
}

struct TotalScreenTimeView: View {
    let totalMinutes: Int

    var body: some View {
        Text("\(totalMinutes)")
            .font(.system(size: 1))
            .foregroundStyle(.clear)
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
