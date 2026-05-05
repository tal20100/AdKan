import SwiftUI

enum WidgetTheme {
    static let brandGreen = Color(red: 0.471, green: 0.788, blue: 0.435)
    static let brandGreenLight = Color(red: 0.773, green: 0.929, blue: 0.729)
    static let brandNavy = Color(red: 0.122, green: 0.306, blue: 0.435)
    static let surfaceDark = Color(red: 0.118, green: 0.122, blue: 0.125)
    static let dangerRed = Color(red: 0.95, green: 0.25, blue: 0.3)

    static let heroGradient = LinearGradient(
        colors: [surfaceDark, brandNavy],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let ringGradient = AngularGradient(
        colors: [brandGreen, brandGreenLight, brandGreen],
        center: .center,
        startAngle: .degrees(-90),
        endAngle: .degrees(270)
    )
}
