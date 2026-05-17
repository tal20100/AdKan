import DeviceActivity
import SwiftUI

@main
struct AdKanDeviceActivityReportExtension: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        TotalScreenTimeReport { totalMinutes in
            TotalScreenTimeView(totalMinutes: totalMinutes)
        }
    }
}
