import SwiftUI

struct TimeReclaimedView: View {
    let savedMinutes: Int
    let goalMinutes: Int
    let todayMinutes: Int
    @EnvironmentObject private var languageManager: LanguageManager
    @AppStorage("genderPreference") private var genderPreference: Int = 0
    @State private var comparisons: [ResolvedComparison] = []
    @State private var animateNumber = false
    @State private var showConfetti = false

    private var underGoal: Bool { todayMinutes <= goalMinutes }
    private var overMinutes: Int { max(0, todayMinutes - goalMinutes) }

    var body: some View {
        VStack(spacing: 0) {
            heroCard
            if todayMinutes > 0 {
                comparisonCards
                    .padding(.top, AdKanTheme.cardSpacing)
            }
        }
        .onAppear {
            comparisons = ComparisonBank.random(savedMinutes: todayMinutes, count: 3)
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
            VStack(spacing: 12) {
                Text(formatMinutes(todayMinutes))
                    .font(AdKanTheme.heroNumber)
                    .foregroundStyle(.white)
                    .scaleEffect(animateNumber ? 1.0 : 0.5)
                    .opacity(animateNumber ? 1.0 : 0)

                Text("home.minToday")
                    .font(AdKanTheme.heroLabel)
                    .foregroundStyle(.white.opacity(0.8))

                usageProgressBar

                if underGoal && savedMinutes > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.seal.fill")
                        Text(verbatim: minutesLeftString(formatMinutes(savedMinutes)))
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(.yellow)
                    .padding(.top, 2)
                } else if !underGoal {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text("home.overGoal \(formatMinutes(overMinutes))" as LocalizedStringKey)
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(Color(red: 1.0, green: 0.6, blue: 0.6))
                    .padding(.top, 2)
                }
            }
            .overlay {
                if showConfetti {
                    ConfettiOverlay()
                }
            }
        }
    }

    private var usageProgressBar: some View {
        GeometryReader { geo in
            let ratio = min(CGFloat(todayMinutes) / CGFloat(max(goalMinutes, 1)), 1.5)
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.2))

                RoundedRectangle(cornerRadius: 4)
                    .fill(underGoal ? Color.white.opacity(0.9) : Color(red: 1.0, green: 0.6, blue: 0.6))
                    .frame(width: geo.size.width * min(ratio, 1.0))

                if goalMinutes > 0 {
                    Rectangle()
                        .fill(Color.white.opacity(0.5))
                        .frame(width: 2)
                        .offset(x: geo.size.width * min(CGFloat(goalMinutes) / CGFloat(max(max(todayMinutes, goalMinutes), 1)), 1.0) - 1)
                }
            }
        }
        .frame(height: 8)
        .padding(.horizontal, 4)
    }

    private var comparisonCards: some View {
        VStack(spacing: 10) {
            Text(underGoal ? "home.couldve" : "home.couldveUsed")
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
            comparisons = ComparisonBank.random(savedMinutes: todayMinutes, count: 3)
        }
    }

    private func minutesLeftString(_ formatted: String) -> String {
        let key: String
        switch genderPreference {
        case 2:  key = "home.minutesLeft.female"
        case 0:  key = "home.minutesLeft.neutral"
        default: key = "home.minutesLeft.male"
        }
        return String(format: NSLocalizedString(key, comment: ""), formatted)
    }

    private func formatMinutes(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
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
