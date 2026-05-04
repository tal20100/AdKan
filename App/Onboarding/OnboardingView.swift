import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void
    @Environment(\.screenTimeProvider) private var provider
    @State private var currentPage = 0
    @State private var answers: [Int] = []
    @State private var showPermissionDeniedAlert = false
    @State private var isRequestingPermission = false
    @AppStorage("dailyGoalMinutes") private var goalMinutes: Int = 120
    @AppStorage("topEnemyApp") private var topEnemyApp: Int = 0
    @AppStorage("crewType") private var crewType: Int = 0
    @AppStorage("screenTimePermissionSkipped") private var permissionSkipped = false
    @AppStorage("genderPreference") private var genderPreference: Int = 0

    private let questions = SurveyData.questions
    private var totalPages: Int { questions.count + 2 } // welcome + questions + permission

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                if currentPage > 0 && currentPage < totalPages - 1 {
                    progressBar
                        .padding(.horizontal, AdKanTheme.screenPadding)
                        .padding(.top, 8)
                }

                TabView(selection: $currentPage) {
                    welcomePage.tag(0)

                    ForEach(Array(questions.enumerated()), id: \.offset) { index, question in
                        questionPage(question, index: index).tag(index + 1)
                    }

                    permissionPage.tag(totalPages - 1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.35), value: currentPage)
            }
        }
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))

                RoundedRectangle(cornerRadius: 4)
                    .fill(AdKanTheme.primaryGradient)
                    .frame(width: geo.size.width * progress)
                    .animation(.spring(response: 0.4), value: progress)
            }
        }
        .frame(height: 6)
    }

    private var progress: CGFloat {
        guard totalPages > 2 else { return 0 }
        return CGFloat(currentPage) / CGFloat(totalPages - 1)
    }

    // MARK: - Welcome

    private var welcomePage: some View {
        VStack(spacing: 32) {
            Spacer()

            Image("adkan_logo_text")
                .resizable()
                .scaledToFit()
                .frame(width: 180, height: 180)

            VStack(spacing: 12) {
                Text("onboarding.welcome.title")
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)

                Text("onboarding.welcome.body")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            AdKanButton(titleKey: "onboarding.welcome.cta", style: .primary) {
                withAnimation { currentPage = 1 }
            }
            .padding(.horizontal, AdKanTheme.screenPadding)
            .padding(.bottom, 48)
        }
    }

    // MARK: - Question

    private func questionPage(_ question: SurveyQuestion, index: Int) -> some View {
        VStack(spacing: 24) {
            Spacer()

            Text(LocalizedStringKey(question.promptKey))
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            VStack(spacing: 10) {
                ForEach(Array(question.options.enumerated()), id: \.offset) { _, option in
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        answers.append(option.value)
                        applyEffect(questionIndex: index, value: option.value)
                        withAnimation { currentPage += 1 }
                    }) {
                        Text(LocalizedStringKey(option.key))
                            .font(.body.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(.horizontal, AdKanTheme.screenPadding)

            Spacer()

            Button("onboarding.skip") {
                withAnimation { currentPage += 1 }
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Permission

    private var permissionPage: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(AdKanTheme.successGreen.opacity(0.15))
                    .frame(width: 100, height: 100)

                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(AdKanTheme.successGreen)
            }

            Text("permission.prompt.title")
                .font(.title2.bold())

            Text("permission.prompt.body")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 12) {
                AdKanButton(titleKey: "permission.prompt.allowCta", style: .primary) {
                    requestScreenTimePermission()
                }
                .disabled(isRequestingPermission)

                AdKanButton(titleKey: "permission.maybeLater", style: .subtle) {
                    permissionSkipped = true
                    onComplete()
                }
            }
            .padding(.horizontal, AdKanTheme.screenPadding)
            .padding(.bottom, 48)
        }
        .alert("permission.denied.title", isPresented: $showPermissionDeniedAlert) {
            Button("permission.denied.openSettings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("permission.maybeLater", role: .cancel) {
                permissionSkipped = true
                onComplete()
            }
        } message: {
            Text("permission.denied.body")
        }
    }

    private func requestScreenTimePermission() {
        isRequestingPermission = true
        Task {
            do {
                try await provider.requestAuthorization()
                let status = await provider.authorizationStatus
                if status == .approved {
                    onComplete()
                } else {
                    showPermissionDeniedAlert = true
                }
            } catch {
                showPermissionDeniedAlert = true
            }
            isRequestingPermission = false
        }
    }

    // MARK: - Effects

    private func applyEffect(questionIndex: Int, value: Int) {
        switch questionIndex {
        case 0: genderPreference = value // Gender preference
        case 3: topEnemyApp = value      // Q3: top enemy app
        case 4: crewType = value         // Q4: crew type
        case 5: goalMinutes = value      // Q5: daily goal
        default: break
        }
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
