import SwiftUI

enum AdKanTheme {
    // MARK: - Colors

    static let primary = Color("AccentColor")
    static let primaryGradient = LinearGradient(
        colors: [Color(red: 0.255, green: 0.420, blue: 0.380), Color(red: 0.18, green: 0.55, blue: 0.52)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let heroGradient = LinearGradient(
        colors: [Color(red: 0.15, green: 0.15, blue: 0.25), Color(red: 0.08, green: 0.22, blue: 0.28)],
        startPoint: .top, endPoint: .bottom
    )
    static let cardBackground = Color(.systemBackground).opacity(0.9)
    static let subtleGray = Color(.systemGray6)

    static let successGreen = Color(red: 0.2, green: 0.78, blue: 0.45)
    static let warningOrange = Color(red: 1.0, green: 0.62, blue: 0.04)
    static let dangerRed = Color(red: 0.95, green: 0.25, blue: 0.3)

    static func minutesColor(_ minutes: Int, goal: Int = 120) -> Color {
        if minutes <= goal { return successGreen }
        if minutes <= goal * 2 { return warningOrange }
        return dangerRed
    }

    // MARK: - Typography

    static let heroNumber = Font.system(size: 72, weight: .bold, design: .rounded)
    static let heroLabel = Font.system(size: 15, weight: .medium, design: .rounded)
    static let cardTitle = Font.system(size: 18, weight: .semibold, design: .rounded)
    static let cardBody = Font.system(size: 14, weight: .regular, design: .rounded)
    static let comparisonText = Font.system(size: 16, weight: .medium, design: .rounded)

    // MARK: - Spacing

    static let screenPadding: CGFloat = 20
    static let cardPadding: CGFloat = 20
    static let cardCornerRadius: CGFloat = 20
    static let buttonCornerRadius: CGFloat = 16
    static let cardSpacing: CGFloat = 16
    static let progressBarHeightCompact: CGFloat = 8
    static let progressBarHeightExpanded: CGFloat = 12
}
