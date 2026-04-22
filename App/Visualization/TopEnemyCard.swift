// On-device card displaying the user's self-selected top enemy app.
import SwiftUI

struct TopEnemyCard: View {
    @AppStorage("topEnemyApp") private var topEnemyApp: Int = 0

    private struct EnemyEntry {
        let name: String
        let emoji: String
    }

    /// Maps the persisted Int to a display entry.
    /// Index 3 uses a localised string key so it adapts to Hebrew / English.
    private var entry: EnemyEntry {
        switch topEnemyApp {
        case 0: return EnemyEntry(name: "TikTok", emoji: "📱")
        case 1: return EnemyEntry(name: "Instagram", emoji: "📸")
        case 2: return EnemyEntry(name: "YouTube", emoji: "▶️")
        default: return EnemyEntry(name: NSLocalizedString("home.topEnemy.other", comment: ""), emoji: "📱")
        }
    }

    var body: some View {
        PlainCard {
            HStack(spacing: 12) {
                Text(entry.emoji)
                    .font(.system(size: 36))

                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.name)
                        .font(AdKanTheme.cardTitle)
                        .foregroundStyle(Color.primary)

                    Text(LocalizedStringKey("home.topEnemy"))
                        .font(AdKanTheme.cardBody)
                        .foregroundStyle(Color.secondary)
                }

                Spacer()

                Image(systemName: "chevron.forward")
                    .foregroundStyle(Color.secondary)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        TopEnemyCard()
    }
    .padding()
}
