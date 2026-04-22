// Capsule progress bar that colours itself via AdKanTheme.minutesColor.
import SwiftUI

struct ProgressBarView: View {
    let currentMinutes: Int
    let goalMinutes: Int
    var compact: Bool = true

    private var fillFraction: Double {
        min(1.0, Double(currentMinutes) / Double(max(1, goalMinutes)))
    }

    private var barHeight: CGFloat {
        compact ? AdKanTheme.progressBarHeightCompact : AdKanTheme.progressBarHeightExpanded
    }

    private var fillColor: Color {
        AdKanTheme.minutesColor(currentMinutes, goal: goalMinutes)
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            if !compact {
                Text("\(currentMinutes)m / \(goalMinutes)m")
                    .font(AdKanTheme.cardBody)
                    .foregroundStyle(Color.secondary)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    // Background track
                    Capsule()
                        .fill(Color(.systemGray5))
                        .frame(height: barHeight)

                    // Filled portion
                    Capsule()
                        .fill(fillColor)
                        .frame(
                            width: proxy.size.width * fillFraction,
                            height: barHeight
                        )
                        .animation(.spring(), value: currentMinutes)
                }
            }
            .frame(height: barHeight)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 24) {
        Group {
            Text(LocalizedStringKey("preview.progressBar.compact"))
                .font(AdKanTheme.cardBody)
            ProgressBarView(currentMinutes: 60, goalMinutes: 120, compact: true)
            ProgressBarView(currentMinutes: 130, goalMinutes: 120, compact: true)
            ProgressBarView(currentMinutes: 300, goalMinutes: 120, compact: true)
        }
        Divider()
        Group {
            Text(LocalizedStringKey("preview.progressBar.expanded"))
                .font(AdKanTheme.cardBody)
            ProgressBarView(currentMinutes: 60, goalMinutes: 120, compact: false)
            ProgressBarView(currentMinutes: 130, goalMinutes: 120, compact: false)
        }
    }
    .padding()
}
