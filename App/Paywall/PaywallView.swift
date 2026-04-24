import SwiftUI

enum PaywallContext {
    case general
    case groupLimit(groupName: String)
}

struct PaywallView: View {
    var context: PaywallContext = .general
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var storeManager: StoreManager
    @State private var selectedTier: Tier = .lifetime
    @State private var animateHero = false
    @State private var showError = false

    var body: some View {
        NavigationStack {
            ZStack {
                AdKanTheme.heroGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        heroSection
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
                    .fill(.yellow.opacity(0.2))
                    .frame(width: 100, height: 100)
                    .scaleEffect(animateHero ? 1.15 : 1.0)

                Image(systemName: "crown.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.yellow)
                    .scaleEffect(animateHero ? 1.05 : 1.0)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    animateHero = true
                }
            }

            switch context {
            case .general:
                Text("paywall.hero.title")
                    .font(.title.bold())
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
            case .groupLimit:
                VStack(spacing: 8) {
                    Text("paywall.group.hero")
                        .font(.title.bold())
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    Text("paywall.group.subtitle")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
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
                            .foregroundStyle(selectedTier == tier ? .yellow : .white.opacity(0.3))
                            .font(.title3)
                    }
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(selectedTier == tier ? Color.white.opacity(0.12) : Color.white.opacity(0.05))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(selectedTier == tier ? Color.yellow.opacity(0.6) : Color.clear, lineWidth: 2)
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
                        .tint(.black)
                } else if let product = storeManager.product(for: selectedTier) {
                    Text(product.displayPrice)
                        .font(.headline)
                } else {
                    Text(LocalizedStringKey(selectedTier.priceKey))
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(.yellow)
            .foregroundStyle(.black)
            .clipShape(RoundedRectangle(cornerRadius: AdKanTheme.buttonCornerRadius))
        }
        .disabled(storeManager.isLoading)
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
                if let url = URL(string: "https://taltalhayun.com/adkan/terms") {
                    UIApplication.shared.open(url)
                }
            }
            Text("·")
            Button("paywall.privacy") {
                if let url = URL(string: "https://taltalhayun.com/adkan/privacy") {
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
                dismiss()
            } else if storeManager.errorMessage != nil {
                showError = true
            }
        }
    }
}
