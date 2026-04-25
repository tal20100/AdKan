import SwiftUI

struct AdKanButton: View {
    let titleKey: LocalizedStringKey
    let style: Style
    let action: () -> Void

    enum Style {
        case primary, secondary, subtle
    }

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            Text(titleKey)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(background)
                .foregroundStyle(foregroundColor)
                .clipShape(RoundedRectangle(cornerRadius: AdKanTheme.buttonCornerRadius))
        }
        .buttonStyle(ScaleButtonStyle())
    }

    @ViewBuilder
    private var background: some View {
        switch style {
        case .primary:
            AdKanTheme.primaryGradient
        case .secondary:
            Color(.systemGray5)
        case .subtle:
            Color.clear
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary: return .white
        case .secondary: return .primary
        case .subtle: return AdKanTheme.primary
        }
    }
}
