import SwiftUI

enum PaywallContext {
    case general
    case groupLimit(groupName: String)
    case feature(PremiumFeature)
}

struct PaywallView: View {
    var context: PaywallContext = .general
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var storeManager: StoreManager
    @State private var selectedTier: Tier = .lifetime
    @State private var animateHero = false
    @State private var showError = false

    private var highlightedFeature: PremiumFeature? {
        if case .feature(let f) = context { return f }
        if case .groupLimit = context { return .largeGroups }
        return nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AdKanTheme.heroGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        heroSection
                        featureGrid
                        tierCards
                        purchaseButton
                        legalLinks
                    }
                    .padding(.vertical, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            }
        }
    }

    private var heroSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AdKanTheme.brandPurple.opacity(0.2))
                    .frame(width: 100, height: 100)
                    .scaleEffect(animateHero ? 1.15 : 1.0)

                Image(systemName: "brain.head.profile.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(AdKanTheme.brandGreen)
                    .scaleEffect(animateHero ? 1.05 : 1.0)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    animateHero = true
                }
            }

            VStack(spacing: 8) {
                Text("paywall.hero.title")
                    .font(.title.bold())
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                if case .groupLimit = context {
                    Text("paywall.group.subtitle")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, AdKanTheme.screenPadding)
        }
    }

    private var featureGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(PremiumFeature.allCases, id: \.self) { feature in
                let isHighlighted = feature == highlightedFeature
                VStack(spacing: 8) {
                    Image(systemName: feature.icon)
                        .font(.title2)
                        .foregroundStyle(isHighlighted ? AdKanTheme.brandPurple : .white.opacity(0.8))

                    Text(LocalizedStringKey(feature.titleKey))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isHighlighted ? Color.white.opacity(0.15) : Color.white.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isHighlighted ? AdKanTheme.brandPurple.opacity(0.6) : Color.clear, lineWidth: 1.5)
                )
            }
        }
        .padding(.horizontal, AdKanTheme.screenPadding)
    }

    private var tierCards: some View {
        VStack(spacing: 12) {
            ForEach(Tier.allCases, id: \.self) { tier in
                Button(action: { withAnimation(.spring(response: 0.3)) { selectedTier = tier } }) {
                    HStack(spacing: 14) {
                        Image(systemName: tier.icon)
                            .font(.title2)
                            .foregroundStyle(tier == .lifetime ? .yellow : .white.opacity(0.8))

                        VStack(alignment: .leading, spacing: 4) {
                            if let badgeKey = tier.badgeKey {
                                Text(LocalizedStringKey(badgeKey))
                                    .font(.caption.bold())
                                    .foregroundStyle(.black)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(.yellow)
                                    .clipShape(Capsule())
                            }
                            Text(LocalizedStringKey(tier.priceKey))
                                .font(.body.weight(.medium))
                                .foregroundStyle(.white)
                        }

                        Spacer()

                        Image(systemName: selectedTier == tier ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(selectedTier == tier ? AdKanTheme.brandPurple : .white.opacity(0.3))
                            .font(.title3)
                    }
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(selectedTier == tier ? Color.white.opacity(0.12) : Color.white.opacity(0.05))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(selectedTier == tier ? AdKanTheme.brandPurple.opacity(0.6) : Color.clear, lineWidth: 2)
                    )
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(.horizontal, AdKanTheme.screenPadding)
    }

    private var purchaseButton: some View {
        Button(action: purchase) {
            Group {
                if storeManager.isLoading {
                    ProgressView()
                        .tint(.white)
                } else if let product = storeManager.product(for: selectedTier) {
                    Text(product.displayPrice)
                        .font(.headline)
                } else if storeManager.products.isEmpty {
                    Text("paywall.productsUnavailable")
                        .font(.subheadline)
                } else {
                    Text(LocalizedStringKey(selectedTier.priceKey))
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(AdKanTheme.premiumGradient)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: AdKanTheme.buttonCornerRadius))
        }
        .disabled(storeManager.isLoading || storeManager.products.isEmpty)
        .padding(.horizontal, AdKanTheme.screenPadding)
        .alert("paywall.error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(storeManager.errorMessage ?? "")
        }
    }

    private var legalLinks: some View {
        HStack(spacing: 16) {
            Button("paywall.restore") {
                Task { await storeManager.restorePurchases() }
            }
            Text("·")
            Button("paywall.terms") {
                if let url = URL(string: "https://adkan.app/terms") {
                    UIApplication.shared.open(url)
                }
            }
            Text("·")
            Button("paywall.privacy") {
                if let url = URL(string: "https://adkan.app/privacy") {
                    UIApplication.shared.open(url)
                }
            }
        }
        .font(.caption)
        .foregroundStyle(.white.opacity(0.5))
    }

    private func purchase() {
        guard let product = storeManager.product(for: selectedTier) else { return }
        Task {
            let success = await storeManager.purchase(product)
            if success {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                dismiss()
            } else if storeManager.errorMessage != nil {
                showError = true
            }
        }
    }
}
