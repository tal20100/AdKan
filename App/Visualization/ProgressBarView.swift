// Capsule progress bar that colours itself via AdKanTheme.minutesColor.
import SwiftUI

struct ProgressBarView: View {
    let currentMinutes: Int
    let goalMinutes: Int
    var compact: Bool = true
    @EnvironmentObject private var languageManager: LanguageManager

    private var fillFraction: Double {
        Double(currentMinutes) / Double(max(1, goalMinutes))
    }

    private var greenFraction: Double {
        min(fillFraction, 1.0)
    }

    private var overflowFraction: Double {
        max(fillFraction - 1.0, 0)
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
                Text("\(TimeFormatter.format(minutes: currentMinutes, locale: languageManager.preferredLanguage)) / \(TimeFormatter.format(minutes: goalMinutes, locale: languageManager.preferredLanguage))")
                    .font(AdKanTheme.cardBody)
                    .foregroundStyle(Color.secondary)
            }

            GeometryReader { proxy in
                let totalWidth = proxy.size.width
                let goalX = totalWidth * min(1.0 / max(fillFraction, 1.0), 1.0)

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AdKanTheme.brandGreen.opacity(0.08))
                        .frame(height: barHeight)

                    Capsule()
                        .fill(AdKanTheme.brandGreen)
                        .frame(
                            width: totalWidth * greenFraction / max(fillFraction, 1.0),
                            height: barHeight
                        )

                    if overflowFraction > 0 {
                        Capsule()
                            .fill(AdKanTheme.dangerRed)
                            .frame(
                                width: totalWidth * overflowFraction / max(fillFraction, 1.0),
                                height: barHeight
                            )
                            .offset(x: goalX)
                    }

                    if fillFraction > 0.05 {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.white.opacity(0.9))
                            .frame(width: 2, height: barHeight + 4)
                            .offset(x: goalX - 1)
                    }
                }
                .animation(.spring(), value: currentMinutes)
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
