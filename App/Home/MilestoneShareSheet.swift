// [SKILL-DECL] Consulted mobile-ios-design skill + AdKanTheme design tokens + App/Visualization/TimeReclaimedView.swift for card patterns
import SwiftUI

/// Full-screen overlay shown when the user hits a streak milestone (7/14/30/100 days).
/// Contains a shareable card and a system share sheet trigger.
struct MilestoneShareSheet: View {
    let streakDays: Int
    let onDismiss: () -> Void

    @State private var showShareSheet = false
    @State private var shareImage: UIImage? = nil
    @State private var cardVisible = false

    private var cardView: some View {
        MilestoneShareCard(streakDays: streakDays)
    }

    var body: some View {
        ZStack {
            // Dimmed backdrop
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 32) {
                cardView
                    .scaleEffect(cardVisible ? 1 : 0.7)
                    .opacity(cardVisible ? 1 : 0)

                VStack(spacing: 12) {
                    AdKanButton(titleKey: "milestone.share.cta", style: .primary) {
                        shareImage = renderCard()
                        showShareSheet = true
                    }

                    Button {
                        onDismiss()
                    } label: {
                        Text("milestone.share.later")
                            .font(AdKanTheme.cardBody)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, AdKanTheme.screenPadding)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                cardVisible = true
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = shareImage {
                ShareSheetController(image: image, onDismiss: onDismiss)
                    .ignoresSafeArea()
            }
        }
    }

    private func renderCard() -> UIImage? {
        let renderer = ImageRenderer(content: MilestoneShareCard(streakDays: streakDays))
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
    }
}

// MARK: - The card itself (rendered both on-screen and into the share image)

struct MilestoneShareCard: View {
    let streakDays: Int

    var body: some View {
        VStack(spacing: 20) {
            Text("🔥")
                .font(.system(size: 72))

            Text("\(streakDays)")
                .font(.system(size: 96, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Text("milestone.share.cardLabel")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))

            Text("milestone.share.brand")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
                .padding(.top, 4)
        }
        .padding(.vertical, 48)
        .padding(.horizontal, 40)
        .frame(maxWidth: 300)
        .background(
            RoundedRectangle(cornerRadius: 32)
                .fill(AdKanTheme.primaryGradient)
        )
        .shadow(color: AdKanTheme.brandGreen.opacity(0.4), radius: 24, x: 0, y: 8)
    }
}

// MARK: - UIActivityViewController wrapper

private struct ShareSheetController: UIViewControllerRepresentable {
    let image: UIImage
    let onDismiss: () -> Void

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let vc = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        vc.completionWithItemsHandler = { _, _, _, _ in onDismiss() }
        return vc
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
