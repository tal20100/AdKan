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

    var icon: String {
        switch self {
        case .thriving: return "brain.head.profile.fill"
        case .onTrack: return "brain.head.profile.fill"
        case .slipping: return "brain.head.profile"
        case .warning: return "brain.head.profile"
        case .spiraling: return "brain.head.profile"
        }
    }

    var color: Color {
        switch self {
        case .thriving, .onTrack: return AdKanTheme.mascotHealthy
        case .slipping: return AdKanTheme.warningOrange
        case .warning: return AdKanTheme.dangerRed.opacity(0.7)
        case .spiraling: return AdKanTheme.mascotUnhealthy
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
}

struct MascotView: View {
    let todayMinutes: Int
    let goalMinutes: Int

    private var state: MascotState {
        MascotState(todayMinutes: todayMinutes, goalMinutes: goalMinutes)
    }

    @State private var bounce = false

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(state.color.opacity(0.15))
                    .frame(width: 90, height: 90)
                    .scaleEffect(bounce ? 1.08 : 1.0)

                Image(systemName: state.icon)
                    .font(.system(size: 44))
                    .foregroundStyle(state.color)
                    .symbolEffect(.pulse, options: .repeating, value: state.color)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    bounce = true
                }
            }

            Text(LocalizedStringKey(state.messageKey))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .animation(.easeInOut, value: state.messageKey)
        }
        .padding(.vertical, 8)
    }
}
