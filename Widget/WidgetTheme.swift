import SwiftUI

enum WidgetTheme {
    // Brand
    static let brandGreen = Color(red: 0.471, green: 0.788, blue: 0.435)
    static let brandGreenLight = Color(red: 0.773, green: 0.929, blue: 0.729)
    static let surfaceDark = Color(red: 0.118, green: 0.122, blue: 0.125)
    static let brandNavy = Color(red: 0.122, green: 0.306, blue: 0.435)

    // Semantic
    static let successGreen = Color(red: 0.2, green: 0.78, blue: 0.45)
    static let warningOrange = Color(red: 1.0, green: 0.62, blue: 0.04)
    static let dangerRed = Color(red: 0.95, green: 0.25, blue: 0.3)

    // Backgrounds
    static let lightBackground = Color(.systemBackground)
    static let darkBackground = LinearGradient(
        colors: [surfaceDark, brandNavy],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static func minutesColor(_ minutes: Int, goal: Int) -> Color {
        if minutes <= goal { return successGreen }
        if minutes <= goal * 2 { return warningOrange }
        return dangerRed
    }

    static func mascotImage(todayMinutes: Int, goalMinutes: Int) -> String {
        let ratio = Double(todayMinutes) / Double(max(goalMinutes, 1))
        switch ratio {
        case ...0.5: return "mascot_state_5"
        case ...1.0: return "mascot_state_4"
        case ...1.5: return "mascot_state_3"
        case ...2.0: return "mascot_state_2"
        default: return "mascot_state_1"
        }
    }
}
