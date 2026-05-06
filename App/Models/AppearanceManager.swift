import SwiftUI

final class AppearanceManager: ObservableObject {
    @AppStorage("appearanceMode") var mode: String = "light"

    var colorScheme: ColorScheme? {
        switch mode {
        case "dark": return .dark
        case "light": return .light
        default: return nil
        }
    }
}
