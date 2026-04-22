// Small rank-change indicator arrow for leaderboard rows.
import SwiftUI

struct RankChangeIndicator: View {
    let previousRank: Int?
    let currentRank: Int

    private enum Direction {
        case improved, declined, unchanged
    }

    private var direction: Direction {
        guard let previous = previousRank else { return .unchanged }
        if currentRank < previous { return .improved }
        if currentRank > previous { return .declined }
        return .unchanged
    }

    private var iconName: String {
        switch direction {
        case .improved:  return "arrow.up.circle.fill"
        case .declined:  return "arrow.down.circle.fill"
        case .unchanged: return "minus.circle"
        }
    }

    private var iconColor: Color {
        switch direction {
        case .improved:  return AdKanTheme.successGreen
        case .declined:  return AdKanTheme.dangerRed
        case .unchanged: return Color(.systemGray3)
        }
    }

    var body: some View {
        Image(systemName: iconName)
            .resizable()
            .scaledToFit()
            .frame(width: 16, height: 16)
            .foregroundStyle(iconColor)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        HStack(spacing: 8) {
            RankChangeIndicator(previousRank: 5, currentRank: 3)
            Text(LocalizedStringKey("preview.rank.improved"))
                .font(AdKanTheme.cardBody)
        }
        HStack(spacing: 8) {
            RankChangeIndicator(previousRank: 3, currentRank: 5)
            Text(LocalizedStringKey("preview.rank.declined"))
                .font(AdKanTheme.cardBody)
        }
        HStack(spacing: 8) {
            RankChangeIndicator(previousRank: 4, currentRank: 4)
            Text(LocalizedStringKey("preview.rank.unchanged"))
                .font(AdKanTheme.cardBody)
        }
        HStack(spacing: 8) {
            RankChangeIndicator(previousRank: nil, currentRank: 2)
            Text(LocalizedStringKey("preview.rank.new"))
                .font(AdKanTheme.cardBody)
        }
    }
    .padding()
}
