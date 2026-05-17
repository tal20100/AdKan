import DeviceActivity
import SwiftUI

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

        return Int(totalSeconds / 60)
    }
}

struct TotalScreenTimeView: View {
    let totalMinutes: Int

    private var hours: Int { totalMinutes / 60 }
    private var mins: Int { totalMinutes % 60 }

    private var isHebrew: Bool {
        Locale.preferredLanguages.first?.hasPrefix("he") == true
    }

    private var timeText: String {
        let h = hours
        let m = mins

        if isHebrew {
            let hp: String = h == 1 ? "שעה" : h == 2 ? "שעתיים" : "\(h) שעות"
            let mp: String = m == 1 ? "דקה" : "\(m) דקות"
            if h > 0 && m > 0 { return "\u{200F}\(hp) ו\u{2011}\(mp)\u{200F}" }
            if h > 0 { return "\u{200F}\(hp)\u{200F}" }
            return "\u{200F}\(mp)\u{200F}"
        } else {
            if h > 0 && m > 0 { return "\(h)h \(m)m" }
            if h > 0 { return "\(h)h" }
            return "\(m)m"
        }
    }

    private var subtitleText: String {
        isHebrew ? "זמן מסך היום" : "Screen time today"
    }

    private var gradientColors: [Color] {
        [Color(red: 0.1, green: 0.45, blue: 0.35), Color(red: 0.05, green: 0.3, blue: 0.4)]
    }

    var body: some View {
        VStack(spacing: 12) {
            Text(timeText)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .foregroundStyle(.white)

            Text(subtitleText)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        .padding(.horizontal, 20)
    }
}

extension DeviceActivityReport.Context {
    static let totalActivity = Self("totalActivity")
}
