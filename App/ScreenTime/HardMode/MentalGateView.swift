import SwiftUI

struct MentalGateView: View {
    let onSelect: (MentalGateReason) -> Void

    @State private var animateIn = false

    var body: some View {
        ZStack {
            AdKanTheme.heroGradient.ignoresSafeArea()

            VStack(spacing: 36) {
                Spacer()

                VStack(spacing: 16) {
                    Image(systemName: "brain.head.profile.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(AdKanTheme.brandGreen)
                        .shadow(color: AdKanTheme.brandGreen.opacity(0.4), radius: 12)

                    Text("hardMode.gate.title")
                        .font(.title2.bold())
                        .foregroundStyle(.white)

                    Text("hardMode.gate.subtitle")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.65))
                        .multilineTextAlignment(.center)
                }
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 20)

                VStack(spacing: 12) {
                    ForEach(Array(MentalGateReason.allCases.enumerated()), id: \.element) { index, reason in
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            onSelect(reason)
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: reason.icon)
                                    .font(.body.bold())
                                    .foregroundStyle(.white)
                                    .frame(width: 36, height: 36)
                                    .background(
                                        Circle()
                                            .fill(.white.opacity(0.12))
                                    )

                                Text(LocalizedStringKey(reason.labelKey))
                                    .font(.body.weight(.medium))

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white.opacity(0.3))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.white.opacity(0.07))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(.white.opacity(0.08), lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 20)
                        .animation(.easeOut(duration: 0.4).delay(0.1 + Double(index) * 0.08), value: animateIn)
                    }
                }
                .padding(.horizontal, AdKanTheme.screenPadding)

                Spacer()
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                animateIn = true
            }
        }
    }
}
