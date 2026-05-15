import DeviceActivity
import SwiftUI

@available(iOS 16.1, *)
struct TotalScreenTimeReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .totalActivity

    let content: (Int) -> TotalScreenTimeView

    func makeConfiguration(
        representing data: DeviceActivityResults<DeviceActivityData>
    ) async -> Int {
        var totalMinutes = 0

        for await activityData in data {
            for await categoryData in activityData.activitySegments {
                totalMinutes += categoryData.totalActivityDuration.toMinutes
            }
        }

        let defaults = UserDefaults(suiteName: "group.com.talhayun.AdKan")
        defaults?.set(totalMinutes, forKey: "widget.todayMinutes")

        return totalMinutes
    }
}

struct TotalScreenTimeView: View {
    let totalMinutes: Int

    var body: some View {
        Color.clear
            .frame(width: 1, height: 1)
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
