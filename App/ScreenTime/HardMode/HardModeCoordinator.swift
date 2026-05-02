import SwiftUI

struct HardModeCoordinator: View {
    let config: HardModeConfig
    let onDismiss: () -> Void

    @State private var step: Step = .idle

    enum Step: Equatable {
        case idle
        case unlockDelay
        case mentalGate
        case frictionPhrase
        case unlocked
    }

    var body: some View {
        ZStack {
            switch step {
            case .idle:
                Color.clear.onAppear { advance(from: .idle) }

            case .unlockDelay:
                UnlockDelayView(totalSeconds: config.unlockDelaySeconds) {
                    advance(from: .unlockDelay)
                }
                .transition(.opacity)

            case .mentalGate:
                MentalGateView { reason in
                    if reason.bypassesBlock {
                        withAnimation(.easeInOut(duration: 0.3)) { step = .unlocked }
                    } else {
                        advance(from: .mentalGate)
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

            case .frictionPhrase:
                FrictionPhraseView {
                    withAnimation(.easeInOut(duration: 0.3)) { step = .unlocked }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

            case .unlocked:
                unlockedView
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.35), value: step)
    }

    private var unlockedView: some View {
        ZStack {
            AdKanTheme.heroGradient.ignoresSafeArea()

            VStack(spacing: 28) {
                ZStack {
                    Circle()
                        .fill(AdKanTheme.brandGreen.opacity(0.15))
                        .frame(width: 120, height: 120)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(AdKanTheme.brandGreen)
                        .shadow(color: AdKanTheme.brandGreen.opacity(0.4), radius: 12)
                }

                Text("hardMode.unlocked")
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onDismiss()
                } label: {
                    Text("hardMode.dismiss")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 48)
                        .padding(.vertical, 16)
                        .background(AdKanTheme.brandGreen)
                        .clipShape(Capsule())
                        .shadow(color: AdKanTheme.brandGreen.opacity(0.3), radius: 8, y: 4)
                }
            }
        }
    }

    private func advance(from current: Step) {
        withAnimation(.easeInOut(duration: 0.35)) {
            switch current {
            case .idle:
                step = config.unlockDelaySeconds > 0 ? .unlockDelay : nextAfterDelay()
            case .unlockDelay:
                step = nextAfterDelay()
            case .mentalGate:
                step = config.frictionPhraseEnabled ? .frictionPhrase : .unlocked
            case .frictionPhrase, .unlocked:
                step = .unlocked
            }
        }
    }

    private func nextAfterDelay() -> Step {
        if config.mentalGateEnabled { return .mentalGate }
        if config.frictionPhraseEnabled { return .frictionPhrase }
        return .unlocked
    }
}
