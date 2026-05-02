import Foundation

struct HardModeConfig: Codable {
    var isEnabled: Bool = false
    var unlockDelaySeconds: Int = 15
    var mentalGateEnabled: Bool = true
    var frictionPhraseEnabled: Bool = false
}

enum MentalGateReason: String, CaseIterable, Codable {
    case habit
    case bored
    case important

    var labelKey: String {
        switch self {
        case .habit: return "hardMode.reason.habit"
        case .bored: return "hardMode.reason.bored"
        case .important: return "hardMode.reason.important"
        }
    }

    var icon: String {
        switch self {
        case .habit: return "arrow.triangle.2.circlepath"
        case .bored: return "moon.zzz.fill"
        case .important: return "exclamationmark.bubble.fill"
        }
    }

    var bypassesBlock: Bool {
        self == .important
    }
}
