// MascotView — brain mascot with state-driven visual effects and animations.
import SwiftUI

enum MascotState {
    case thriving
    case onTrack
    case slipping
    case warning
    case spiraling

    init(todayMinutes: Int, goalMinutes: Int) {
        let ratio = Double(todayMinutes) / Double(max(goalMinutes, 1))
        switch ratio {
        case ...0.5: self = .thriving
        case ...1.0: self = .onTrack
        case ...1.5: self = .slipping
        case ...2.0: self = .warning
        default: self = .spiraling
        }
    }

    var messageKey: String {
        switch self {
        case .thriving: return "mascot.thriving"
        case .onTrack: return "mascot.onTrack"
        case .slipping: return "mascot.slipping"
        case .warning: return "mascot.warning"
        case .spiraling: return "mascot.spiraling"
        }
    }

    var imageName: String {
        switch self {
        case .spiraling: return "mascot_state_1"
        case .warning:   return "mascot_state_2"
        case .slipping:  return "mascot_state_3"
        case .onTrack:   return "mascot_state_4"
        case .thriving:  return "mascot_state_5"
        }
    }

    var glowColor: Color {
        switch self {
        case .thriving: return AdKanTheme.brandGreen
        case .onTrack: return AdKanTheme.mascotHealthy
        case .slipping: return AdKanTheme.warningOrange.opacity(0.7)
        case .warning: return AdKanTheme.warningOrange
        case .spiraling: return AdKanTheme.mascotUnhealthy
        }
    }

    var showSparkles: Bool {
        self == .thriving
    }

    /// Index into the 5-dot state indicator (0 = thriving, 4 = spiraling)
    var dotIndex: Int {
        switch self {
        case .thriving: return 0
        case .onTrack: return 1
        case .slipping: return 2
        case .warning: return 3
        case .spiraling: return 4
        }
    }
}

struct MascotView: View {
    let todayMinutes: Int
    let goalMinutes: Int

    private var state: MascotState {
        MascotState(todayMinutes: todayMinutes, goalMinutes: goalMinutes)
    }

    @State private var glowPulse = false
    @State private var sparkleOffset1: CGFloat = 0
    @State private var sparkleOffset2: CGFloat = 0
    @State private var sparkleOffset3: CGFloat = 0
    @State private var shakeOffset: CGFloat = 0

    var body: some View {
        VStack(spacing: 16) {
            mascotStack
            stateDots
            Text(LocalizedStringKey(state.messageKey))
                .font(AdKanTheme.cardBody)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .animation(.easeInOut, value: state.messageKey)
        }
        .padding(.vertical, 12)
        .onChange(of: state.messageKey) { _ in
            restartAnimations()
        }
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - Mascot stack

    private var mascotStack: some View {
        ZStack {
            // Soft glow circle behind mascot
            Circle()
                .fill(state.glowColor.opacity(0.18))
                .frame(width: 160, height: 160)
                .scaleEffect(glowPulse ? 1.10 : 1.0)
                .blur(radius: glowPulse ? 8 : 4)
                .animation(
                    .easeInOut(duration: 2.2).repeatForever(autoreverses: true),
                    value: glowPulse
                )

            // Mascot image
            Image(state.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 130, height: 130)
                .offset(x: shakeOffset)
                .shadow(color: state.glowColor.opacity(0.35), radius: 10, x: 0, y: 4)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.4), value: state.imageName)

            // Sparkle overlays for thriving state
            if state.showSparkles {
                sparkleLayer
            }
        }
    }

    // MARK: - Sparkles

    private var sparkleLayer: some View {
        ZStack {
            Text("✨")
                .font(.system(size: 20))
                .offset(x: -58, y: -40 + sparkleOffset1)
                .opacity(0.9)

            Text("✨")
                .font(.system(size: 14))
                .offset(x: 62, y: -28 + sparkleOffset2)
                .opacity(0.85)

            Text("✨")
                .font(.system(size: 17))
                .offset(x: 48, y: 44 + sparkleOffset3)
                .opacity(0.8)
        }
    }

    // MARK: - State dots

    private var stateDots: some View {
        HStack(spacing: 7) {
            ForEach(0..<5) { index in
                let isActive = index == state.dotIndex
                Circle()
                    .fill(isActive ? state.glowColor : Color(.systemGray4))
                    .frame(width: isActive ? 10 : 7, height: isActive ? 10 : 7)
                    .animation(.spring(response: 0.3, dampingFraction: 0.65), value: state.dotIndex)
            }
        }
    }

    // MARK: - Animation control

    private func startAnimations() {
        glowPulse = true

        if state.showSparkles {
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true).delay(0.0)) {
                sparkleOffset1 = -10
            }
            withAnimation(.easeInOut(duration: 2.1).repeatForever(autoreverses: true).delay(0.4)) {
                sparkleOffset2 = -8
            }
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true).delay(0.8)) {
                sparkleOffset3 = 10
            }
        }

        if state == .spiraling {
            startShake()
        }
    }

    private func restartAnimations() {
        glowPulse = false
        sparkleOffset1 = 0
        sparkleOffset2 = 0
        sparkleOffset3 = 0
        shakeOffset = 0
        // Let layout settle before restarting
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            startAnimations()
        }
    }

    private func startShake() {
        let shakeAnimation = Animation.easeInOut(duration: 0.08).repeatCount(6, autoreverses: true)
        withAnimation(shakeAnimation) {
            shakeOffset = 6
        }
        // Re-trigger shake every ~3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            guard state == .spiraling else { return }
            shakeOffset = 0
            startShake()
        }
    }
}
