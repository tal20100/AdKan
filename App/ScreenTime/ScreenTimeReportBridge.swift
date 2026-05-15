import SwiftUI
#if canImport(DeviceActivity)
import DeviceActivity

extension DeviceActivityReport.Context {
    static let totalActivity = Self("totalActivity")
}

struct ScreenTimeReportBridge: View {
    var body: some View {
        DeviceActivityReport(.totalActivity, filter: Self.todayFilter())
            .frame(maxWidth: .infinity, minHeight: 50)
    }

    static func todayFilter() -> DeviceActivityFilter {
        DeviceActivityFilter(
            segment: .daily(
                during: DateInterval(
                    start: Calendar.current.startOfDay(for: Date()),
                    end: Date()
                )
            )
        )
    }
}
#endif
