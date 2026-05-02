import SwiftUI

struct PremiumGateModifier: ViewModifier {
    let feature: PremiumFeature
    @EnvironmentObject private var storeManager: StoreManager
    @State private var showPaywall = false

    func body(content: Content) -> some View {
        if storeManager.canAccess(feature) {
            content
        } else {
            content
                .blur(radius: 3)
                .allowsHitTesting(false)
                .overlay {
                    RoundedRectangle(cornerRadius: AdKanTheme.cardCornerRadius)
                        .fill(.ultraThinMaterial.opacity(0.4))
                }
                .overlay(alignment: .topTrailing) {
                    premiumBadge
                        .padding(12)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showPaywall = true
                }
                .sheet(isPresented: $showPaywall) {
                    PaywallView(context: .feature(feature))
                }
        }
    }

    private var premiumBadge: some View {
        HStack(spacing: 5) {
            Image(systemName: "lock.fill")
                .font(.system(size: 10, weight: .bold))
            Text("premium.badge")
                .font(.system(size: 11, weight: .bold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(AdKanTheme.premiumGradient)
        .clipShape(Capsule())
        .shadow(color: AdKanTheme.brandPurple.opacity(0.3), radius: 6, y: 2)
        .accessibilityLabel(Text("premium.badge.accessibility"))
    }
}

extension View {
    func premiumGated(_ feature: PremiumFeature) -> some View {
        modifier(PremiumGateModifier(feature: feature))
    }
}
