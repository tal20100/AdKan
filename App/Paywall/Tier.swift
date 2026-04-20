import Foundation

enum Tier: String, CaseIterable {
    case lifetime
    case annual
    case monthly

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
}
