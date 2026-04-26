import SwiftUI

struct TimeReclaimedView: View {
    let savedMinutes: Int
    let goalMinutes: Int
    let todayMinutes: Int
    @EnvironmentObject private var languageManager: LanguageManager
    @State private var comparisons: [ResolvedComparison] = []
    @State private var animateNumber = false
    @State private var showConfetti = false

    private var underGoal: Bool { savedMinutes > 0 && todayMinutes > 0 }
    private var hours: Int { savedMinutes / 60 }
    private var mins: Int { savedMinutes % 60 }

    var body: some View {
        VStack(spacing: 0) {
            heroCard
            if !comparisons.isEmpty {
                comparisonCards
                    .padding(.top, AdKanTheme.cardSpacing)
            }
        }
        .onAppear {
            comparisons = ComparisonBank.random(savedMinutes: savedMinutes, count: 3)
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.3)) {
                animateNumber = true
            }
            if underGoal {
                withAnimation(.easeIn.delay(1.0)) { showConfetti = true }
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }

    private var heroCard: some View {
        GradientCard(gradient: underGoal ? goalMetGradient : defaultGradient) {
            VStack(spacing: 8) {
                Text(timeString)
                    .font(AdKanTheme.heroNumber)
                    .foregroundStyle(.white)
                    .scaleEffect(animateNumber ? 1.0 : 0.5)
                    .opacity(animateNumber ? 1.0 : 0)

                Text(underGoal ? "home.savedToday" : "home.putPhoneDown")
                    .font(AdKanTheme.heroLabel)
                    .foregroundStyle(.white.opacity(0.8))

                if underGoal {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.seal.fill")
                        Text("home.goalReached")
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(.yellow)
                    .padding(.top, 4)
                }
            }
            .overlay {
                if showConfetti {
                    ConfettiOverlay()
                }
            }
        }
    }

    private var comparisonCards: some View {
        VStack(spacing: 10) {
            Text("home.couldve")
                .font(AdKanTheme.cardBody)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(Array(comparisons.enumerated()), id: \.element.id) { index, comparison in
                ComparisonRow(comparison: comparison)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .animation(.spring(response: 0.5).delay(Double(index) * 0.15), value: comparisons.count)
            }

            Button(action: refreshComparisons) {
                HStack(spacing: 6) {
                    Image(systemName: "shuffle")
                    Text("home.more")
                }
                .font(.footnote.bold())
                .foregroundStyle(AdKanTheme.primary)
            }
            .padding(.top, 4)
        }
    }

    private func refreshComparisons() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.spring(response: 0.4)) {
            comparisons = ComparisonBank.random(savedMinutes: savedMinutes, count: 3)
        }
    }

    private var timeString: String {
        if hours > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(mins)m"
    }

    private var goalMetGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.1, green: 0.45, blue: 0.35), Color(red: 0.05, green: 0.3, blue: 0.4)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    private var defaultGradient: LinearGradient {
        AdKanTheme.heroGradient
    }
}

private struct ComparisonRow: View {
    let comparison: ResolvedComparison
    @EnvironmentObject private var languageManager: LanguageManager

    var body: some View {
        HStack(spacing: 14) {
            Text(comparison.icon)
                .font(.title2)

            Text(comparison.text(locale: languageManager.preferredLanguage))
                .font(AdKanTheme.comparisonText)
                .foregroundStyle(.primary)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct ConfettiOverlay: View {
    @State private var particles: [(id: Int, x: CGFloat, y: CGFloat, color: Color, rotation: Double)] = []

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles, id: \.id) { p in
                    Circle()
                        .fill(p.color)
                        .frame(width: 6, height: 6)
                        .rotationEffect(.degrees(p.rotation))
                        .position(x: p.x, y: p.y)
                }
            }
            .onAppear {
                let colors: [Color] = [AdKanTheme.brandGreen, AdKanTheme.brandGreenLight, AdKanTheme.brandPurple, AdKanTheme.brandPurpleLight, .yellow]
                for i in 0..<20 {
                    let startX = geo.size.width / 2 + CGFloat.random(in: -30...30)
                    particles.append((
                        id: i,
                        x: startX,
                        y: geo.size.height / 2,
                        color: colors.randomElement()!,
                        rotation: Double.random(in: 0...360)
                    ))
                }
                withAnimation(.easeOut(duration: 1.5)) {
                    for i in particles.indices {
                        particles[i].x += CGFloat.random(in: -100...100)
                        particles[i].y += CGFloat.random(in: -120...(-20))
                        particles[i].rotation += Double.random(in: 90...360)
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation { particles.removeAll() }
                }
            }
        }
        .allowsHitTesting(false)
    }
}
