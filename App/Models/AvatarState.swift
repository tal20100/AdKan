import SwiftUI

enum AvatarState: String, CaseIterable, Codable {
    case streakWinning
    case onTrack
    case neutral
    case slipping
    case spiraling

    static func from(todayMinutes: Int, goalMinutes: Int, streakDays: Int = 0) -> AvatarState {
        let ratio = goalMinutes > 0 ? Double(todayMinutes) / Double(goalMinutes) : 1.0
        if ratio <= 1.0 && streakDays >= 3 { return .streakWinning }
        if ratio <= 1.0 { return .onTrack }
        if ratio <= 1.15 { return .neutral }
        if ratio <= 2.0 { return .slipping }
        return .spiraling
    }

    var systemImageName: String {
        switch self {
        case .streakWinning: return "sparkles"
        case .onTrack: return "face.smiling"
        case .neutral: return "face.dashed"
        case .slipping: return "exclamationmark.triangle"
        case .spiraling: return "flame"
        }
    }

    var nameKey: String {
        "avatar.state.\(rawValue)"
    }

    var iconSize: CGFloat {
        switch self {
        case .streakWinning: return 48
        case .onTrack: return 44
        case .neutral: return 44
        case .slipping: return 44
        case .spiraling: return 48
        }
    }
}
