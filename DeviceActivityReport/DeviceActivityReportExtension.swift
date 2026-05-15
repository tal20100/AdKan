import DeviceActivity
import SwiftUI

@main
struct AdKanDeviceActivityReportExtension: DeviceActivityReportExtension {
    init() {
        let defaults = UserDefaults(suiteName: "group.com.talhayun.AdKan")
        defaults?.set("ext_init", forKey: "report.phase")
        defaults?.set(Date().timeIntervalSince1970, forKey: "report.initTime")
        defaults?.synchronize()
    }

    var body: some DeviceActivityReportScene {
        TotalScreenTimeReport { totalMinutes in
            TotalScreenTimeView(totalMinutes: totalMinutes)
        }
    }
}
