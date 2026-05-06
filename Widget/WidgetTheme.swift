import SwiftUI

enum WidgetTheme {
    static let brandGreen = Color(red: 0.471, green: 0.788, blue: 0.435)
    static let brandGreenLight = Color(red: 0.773, green: 0.929, blue: 0.729)
    static let brandNavy = Color(red: 0.122, green: 0.306, blue: 0.435)
    static let surfaceDark = Color(red: 0.118, green: 0.122, blue: 0.125)
    static let dangerRed = Color(red: 0.95, green: 0.25, blue: 0.3)

    static let lightGradient = LinearGradient(
        colors: [brandGreen, brandGreenLight],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let darkGradient = LinearGradient(
        colors: [surfaceDark, brandNavy],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static func background(for scheme: ColorScheme) -> LinearGradient {
        scheme == .dark ? darkGradient : lightGradient
    }

    static func ringStroke(for scheme: ColorScheme) -> Color {
        scheme == .dark ? brandGreen : .white
    }

    static func ringTrack(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.25)
    }
}
