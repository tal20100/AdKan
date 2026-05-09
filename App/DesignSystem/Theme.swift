import SwiftUI

enum AdKanTheme {
    // MARK: - Brand Colors

    static let primary = Color("AccentColor")
    static let brandGreen = Color(red: 0.471, green: 0.788, blue: 0.435)
    static let brandGreenLight = Color(red: 0.773, green: 0.929, blue: 0.729)
    static let brandPurple = Color(red: 0.651, green: 0.545, blue: 0.969)
    static let brandPurpleLight = Color(red: 0.839, green: 0.729, blue: 0.945)
    static let surfaceDark = Color(red: 0.118, green: 0.122, blue: 0.125)
    static let surfaceGray = Color(red: 0.400, green: 0.435, blue: 0.447)
    static let brandNavy = Color(red: 0.122, green: 0.306, blue: 0.435)

    // MARK: - Mascot Colors

    static let mascotHealthy = brandGreen
    static let mascotUnhealthy = surfaceGray

    // MARK: - Gradients

    static let primaryGradient = LinearGradient(
        colors: [Color(red: 0.28, green: 0.60, blue: 0.26), Color(red: 0.48, green: 0.78, blue: 0.42)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let heroGradient = LinearGradient(
        colors: [surfaceDark, brandNavy],
        startPoint: .top, endPoint: .bottom
    )
    static let premiumGradient = LinearGradient(
        colors: [brandPurple, brandPurpleLight],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    // MARK: - Semantic Colors

    static let successGreen = Color(red: 0.2, green: 0.78, blue: 0.45)
    static let warningOrange = Color(red: 1.0, green: 0.62, blue: 0.04)
    static let dangerRed = Color(red: 0.95, green: 0.25, blue: 0.3)

    static let cardBackground = Color(.systemBackground).opacity(0.9)
    static let subtleGray = Color(.systemGray6)

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
