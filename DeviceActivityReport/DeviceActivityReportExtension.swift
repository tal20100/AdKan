import DeviceActivity
import SwiftUI

@main
struct AdKanDeviceActivityReportExtension: DeviceActivityReportExtension {
    init() {
        if let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.talhayun.AdKan")?
            .appendingPathComponent("report-data.plist") {
            let dict: NSDictionary = ["phase": "ext_init", "initTime": Date().timeIntervalSince1970]
            dict.write(to: url, atomically: true)
        }
    }

    var body: some DeviceActivityReportScene {
        TotalScreenTimeReport { totalMinutes in
            TotalScreenTimeView(totalMinutes: totalMinutes)
        }
    }
}
