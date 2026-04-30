import SwiftUI

struct CircularProgressView: View {
    let progress: Double
    var lineWidth: CGFloat = 4
    var trackColor: Color = Color(.systemGray5)
    var progressColor: Color = AdKanTheme.primary

    var body: some View {
        ZStack {
            Circle()
                .stroke(trackColor, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(progressColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.4), value: progress)
        }
    }
}
