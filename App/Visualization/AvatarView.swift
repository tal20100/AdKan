// Animated avatar circle that reflects the user's current AvatarState.
import SwiftUI

struct AvatarView: View {
    let state: AvatarState
    var size: CGFloat = 120

    @State private var animating = false

    private var color: Color { AdKanTheme.avatarColor(for: state) }

    // Computed icon size relative to the circle size.
    private var iconSize: CGFloat { size * (state.iconSize / 120) }

    var body: some View {
        ZStack {
            // Fill layer
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: size, height: size)

            // Ring stroke
            Circle()
                .strokeBorder(color, lineWidth: 2.5)
                .frame(width: size, height: size)

            // SF Symbol icon
            Image(systemName: state.systemImageName)
                .resizable()
                .scaledToFit()
                .frame(width: iconSize, height: iconSize)
                .foregroundStyle(color)
        }
        .modifier(AvatarAnimationModifier(state: state, animating: animating))
        .animation(.spring(), value: state)
        .onAppear { animating = true }
    }
}

// MARK: - Animation modifier

private struct AvatarAnimationModifier: ViewModifier {
    let state: AvatarState
    let animating: Bool

    func body(content: Content) -> some View {
        switch state {
        case .streakWinning:
            content
                .scaleEffect(animating ? 1.08 : 1.0)
                .animation(
                    .easeInOut(duration: 0.9).repeatForever(autoreverses: true),
                    value: animating
                )
        case .onTrack:
            content
                .offset(y: animating ? -4 : 0)
                .animation(
                    .easeInOut(duration: 1.1).repeatForever(autoreverses: true),
                    value: animating
                )
        case .neutral:
            content
        case .slipping:
            content
                .rotationEffect(.degrees(animating ? 3 : -3))
                .animation(
                    .easeInOut(duration: 0.35).repeatForever(autoreverses: true),
                    value: animating
                )
        case .spiraling:
            content
                .scaleEffect(animating ? 1.12 : 1.0)
                .opacity(animating ? 0.7 : 1.0)
                .animation(
                    .easeInOut(duration: 0.7).repeatForever(autoreverses: true),
                    value: animating
                )
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 24) {
        ForEach(AvatarState.allCases, id: \.self) { state in
            HStack(spacing: 16) {
                AvatarView(state: state, size: 80)
                Text(LocalizedStringKey(state.nameKey))
                    .font(AdKanTheme.cardBody)
            }
        }
    }
    .padding()
}
