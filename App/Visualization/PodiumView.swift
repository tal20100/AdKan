import SwiftUI

struct PodiumEntry: Identifiable {
    let id: String
    let displayName: String
    let avatarEmoji: String
    let minutes: Int
    let streak: Int
    let leagueBadge: LeagueBadge
    let rank: Int
    let isCurrentUser: Bool
}

struct PodiumView: View {
    let entries: [PodiumEntry]
    let formatMinutes: (Int) -> String
    @State private var appeared = false

    private var first: PodiumEntry? { entries.first { $0.rank == 1 } }
    private var second: PodiumEntry? { entries.first { $0.rank == 2 } }
    private var third: PodiumEntry? { entries.first { $0.rank == 3 } }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if let second {
                podiumColumn(entry: second, height: 80, delay: 0.15)
            }
            if let first {
                podiumColumn(entry: first, height: 110, delay: 0.0, isFirst: true)
            }
            if let third {
                podiumColumn(entry: third, height: 60, delay: 0.25)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AdKanTheme.cardCornerRadius)
                .fill(AdKanTheme.primaryGradient)
        )
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                appeared = true
            }
        }
    }

    private func podiumColumn(entry: PodiumEntry, height: CGFloat, delay: Double, isFirst: Bool = false) -> some View {
        VStack(spacing: 6) {
            if isFirst {
                Text("👑")
                    .font(.system(size: 20))
                    .scaleEffect(appeared ? 1 : 0)
                    .animation(.spring(response: 0.5).delay(0.4), value: appeared)
            }

            ZStack {
                Circle()
                    .fill(.white.opacity(entry.isCurrentUser ? 0.3 : 0.15))
                    .frame(width: isFirst ? 56 : 44, height: isFirst ? 56 : 44)

                Text(entry.avatarEmoji)
                    .font(.system(size: isFirst ? 30 : 24))
            }
            .scaleEffect(appeared ? 1 : 0.3)
            .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(delay), value: appeared)

            Text(entry.displayName)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .frame(maxWidth: 80)

            if entry.minutes > 0 {
                Text(formatMinutes(entry.minutes))
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            } else {
                Text("---")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
            }

            HStack(spacing: 3) {
                if entry.streak > 0 {
                    Text("🔥\(entry.streak)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                }
                if entry.leagueBadge.displayable {
                    Text(entry.leagueBadge.emoji)
                        .font(.system(size: 10))
                }
            }
            .frame(height: 14)

            RoundedRectangle(cornerRadius: 6)
                .fill(.white.opacity(0.15))
                .frame(height: height * (appeared ? 1 : 0.3))
                .frame(maxWidth: .infinity)
                .overlay(alignment: .top) {
                    Text("#\(entry.rank)")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(.top, 8)
                }
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(delay), value: appeared)
        }
        .frame(maxWidth: .infinity)
    }
}
