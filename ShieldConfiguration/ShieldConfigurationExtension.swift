import ManagedSettings
import ManagedSettingsUI
import UIKit

class AdKanShieldConfigurationExtension: ShieldConfigurationDataSource {

    private var defaults: UserDefaults? {
        UserDefaults(suiteName: "group.com.talhayun.AdKan")
    }

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        buildConfiguration()
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        buildConfiguration()
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        buildConfiguration()
    }

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        buildConfiguration()
    }

    private func buildConfiguration() -> ShieldConfiguration {
        let store = defaults

        let title = store?.string(forKey: "shield.title") ?? "עד כאן"
        let subtitle = store?.string(forKey: "shield.subtitle")
            ?? "You chose to limit this app. Stay strong!"
        let primaryLabel = store?.string(forKey: "shield.primaryButton") ?? "Close"
        let secondaryLabel = store?.string(forKey: "shield.secondaryButton") ?? "Allow 1 min"
        let isPremium = store?.bool(forKey: "shield.isPremium") ?? false
        let themeIndex = store?.integer(forKey: "shield.themeIndex") ?? 0

        let theme = ShieldTheme.all[min(themeIndex, ShieldTheme.all.count - 1)]
        let bg = isPremium ? theme.background : ShieldTheme.defaultTheme.background
        let accent = isPremium ? theme.accent : ShieldTheme.defaultTheme.accent

        return ShieldConfiguration(
            backgroundBlurStyle: .dark,
            backgroundColor: bg,
            icon: nil,
            title: ShieldConfiguration.Label(text: title, color: .white),
            subtitle: ShieldConfiguration.Label(
                text: subtitle,
                color: UIColor(white: 0.85, alpha: 1)
            ),
            primaryButtonLabel: ShieldConfiguration.Label(text: primaryLabel, color: .white),
            primaryButtonBackgroundColor: accent,
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: secondaryLabel,
                color: UIColor(white: 0.8, alpha: 1)
            )
        )
    }
}

private struct ShieldTheme {
    let background: UIColor
    let accent: UIColor

    static let defaultTheme = ShieldTheme(
        background: UIColor(red: 0.06, green: 0.06, blue: 0.14, alpha: 1),
        accent: UIColor(red: 0.15, green: 0.68, blue: 0.38, alpha: 1)
    )

    static let forest = ShieldTheme(
        background: UIColor(red: 0.06, green: 0.14, blue: 0.1, alpha: 1),
        accent: UIColor(red: 0.2, green: 0.78, blue: 0.35, alpha: 1)
    )

    static let purple = ShieldTheme(
        background: UIColor(red: 0.1, green: 0.05, blue: 0.15, alpha: 1),
        accent: UIColor(red: 0.69, green: 0.32, blue: 0.87, alpha: 1)
    )

    static let midnight = ShieldTheme(
        background: UIColor(red: 0.02, green: 0.02, blue: 0.08, alpha: 1),
        accent: UIColor(red: 0.3, green: 0.5, blue: 0.9, alpha: 1)
    )

    static let all: [ShieldTheme] = [defaultTheme, forest, purple, midnight]
}
