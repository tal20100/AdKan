import SwiftUI

struct UnlockDelayView: View {
    let totalSeconds: Int
    let onComplete: () -> Void

    @State private var remaining: Int
    @State private var timer: Timer?
    @State private var pulseScale: CGFloat = 1.0

    init(totalSeconds: Int, onComplete: @escaping () -> Void) {
        self.totalSeconds = totalSeconds
        self.onComplete = onComplete
        self._remaining = State(initialValue: totalSeconds)
    }

    private var progress: Double {
        1.0 - Double(remaining) / Double(max(totalSeconds, 1))
    }

    var body: some View {
        ZStack {
            AdKanTheme.heroGradient.ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(AdKanTheme.brandPurple.opacity(0.08))
                        .frame(width: 200, height: 200)
                        .scaleEffect(pulseScale)

                    CircularProgressView(
                        progress: progress,
                        lineWidth: 6,
                        trackColor: .white.opacity(0.12),
                        progressColor: .white.opacity(0.9)
                    )
                    .frame(width: 160, height: 160)
                    .animation(.linear(duration: 1), value: remaining)

                    Text("\(remaining)")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3), value: remaining)
                }

                VStack(spacing: 12) {
                    Text("hardMode.delay.title")
                        .font(.title2.bold())
                        .foregroundStyle(.white)

                    Text("hardMode.delay.body")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.65))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                Spacer()
                Spacer()
            }
        }
        .onAppear {
            startTimer()
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                pulseScale = 1.08
            }
        }
        .onDisappear { timer?.invalidate() }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if remaining > 1 {
                remaining -= 1
                UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.3)
            } else {
                timer?.invalidate()
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                onComplete()
            }
        }
    }
}
