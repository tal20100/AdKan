import SwiftUI
#if canImport(DeviceActivity)
import DeviceActivity

extension DeviceActivityReport.Context {
    static let totalActivity = Self("totalActivity")
}

struct ScreenTimeReportBridge: View {
    @State private var filter = DeviceActivityFilter(
        segment: .daily(
            during: DateInterval(
                start: Calendar.current.startOfDay(for: Date()),
                end: Date()
            )
        )
    )

    var body: some View {
        DeviceActivityReport(.totalActivity, filter: filter)
            .frame(width: 0, height: 0)
            .opacity(0)
            .allowsHitTesting(false)
    }
}
#endif
