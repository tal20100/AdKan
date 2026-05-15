import SwiftUI
#if canImport(DeviceActivity)
import DeviceActivity

extension DeviceActivityReport.Context {
    static let totalActivity = Self("totalActivity")
}

struct ScreenTimeReportBridge: View {
    @State private var filter = Self.todayFilter()

    var body: some View {
        DeviceActivityReport(.totalActivity, filter: filter)
            .frame(height: 1)
            .opacity(0.01)
            .allowsHitTesting(false)
            .onAppear {
                filter = Self.todayFilter()
            }
    }

    private static func todayFilter() -> DeviceActivityFilter {
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
