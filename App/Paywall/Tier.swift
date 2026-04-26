import Foundation

enum Tier: String, CaseIterable {
    case lifetime
    case annual
    case monthly

    var productID: String {
        switch self {
        case .lifetime: return "com.taltalhayun.adkan.lifetime"
        case .annual: return "com.taltalhayun.adkan.subscription.annual"
        case .monthly: return "com.taltalhayun.adkan.subscription.monthly"
        }
    }

    var icon: String {
        switch self {
        case .lifetime: return "crown.fill"
        case .annual: return "calendar"
        case .monthly: return "clock"
        }
    }

    var priceKey: String {
        switch self {
        case .lifetime: return "paywall.tier.lifetime.price"
        case .annual: return "paywall.tier.annual.price"
        case .monthly: return "paywall.tier.monthly.price"
        }
    }

    var badgeKey: String? {
        switch self {
        case .lifetime: return "paywall.tier.lifetime.badge"
        default: return nil
        }
    }

    static func from(productID: String) -> Tier? {
        allCases.first { $0.productID == productID }
    }
}

enum PremiumFeature: String, CaseIterable {
    case unlimitedGroups
    case largeGroups
    case weeklyChallenges
    case customAppLimits
    case premiumBadges
    case enhancedRecap
    case customThemes

    var titleKey: String { "premium.feature.\(rawValue).title" }
    var descriptionKey: String { "premium.feature.\(rawValue).desc" }

    var icon: String {
        switch self {
        case .unlimitedGroups: return "person.3.fill"
        case .largeGroups: return "person.crop.rectangle.stack.fill"
        case .weeklyChallenges: return "trophy.fill"
        case .customAppLimits: return "slider.horizontal.3"
        case .premiumBadges: return "medal.fill"
        case .enhancedRecap: return "chart.bar.fill"
        case .customThemes: return "paintpalette.fill"
        }
    }

    var isHardGate: Bool {
        switch self {
        case .unlimitedGroups, .largeGroups: return true
        default: return false
        }
    }
}
