import SwiftUI

struct GradientCard<Content: View>: View {
    let gradient: LinearGradient
    @ViewBuilder let content: () -> Content

    init(
        gradient: LinearGradient = AdKanTheme.primaryGradient,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.gradient = gradient
        self.content = content
    }

    var body: some View {
        content()
            .padding(AdKanTheme.cardPadding)
            .frame(maxWidth: .infinity)
            .background(gradient)
            .clipShape(RoundedRectangle(cornerRadius: AdKanTheme.cardCornerRadius))
            .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
    }
}

struct PlainCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(AdKanTheme.cardPadding)
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: AdKanTheme.cardCornerRadius))
            .shadow(color: .black.opacity(0.06), radius: 10, y: 3)
    }
}
