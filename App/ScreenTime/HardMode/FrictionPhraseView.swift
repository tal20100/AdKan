import SwiftUI

struct FrictionPhraseView: View {
    let onComplete: () -> Void
    @EnvironmentObject private var languageManager: LanguageManager

    @State private var input: String = ""
    @State private var shake = false
    @State private var animateIn = false

    private var targetPhrase: String {
        if languageManager.preferredLanguage == "he" {
            return "אני בוחר להשתמש בזמן שלי בחכמה"
        }
        return "I choose to spend my time wisely"
    }

    private var isMatch: Bool {
        input.trimmingCharacters(in: .whitespaces).lowercased() == targetPhrase.lowercased()
    }

    var body: some View {
        ZStack {
            AdKanTheme.heroGradient.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 16) {
                    Image(systemName: "pencil.line")
                        .font(.system(size: 40))
                        .foregroundStyle(AdKanTheme.brandPurple)
                        .shadow(color: AdKanTheme.brandPurple.opacity(0.4), radius: 10)

                    Text("hardMode.friction.title")
                        .font(.title2.bold())
                        .foregroundStyle(.white)

                    Text("hardMode.friction.instruction")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.65))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 15)

                VStack(spacing: 16) {
                    Text(targetPhrase)
                        .font(.body.weight(.medium).italic())
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(16)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(.white.opacity(0.06))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(.white.opacity(0.1), lineWidth: 1)
                                )
                        )

                    TextField("hardMode.friction.placeholder", text: $input)
                        .textFieldStyle(.plain)
                        .font(.body)
                        .foregroundStyle(.white)
                        .tint(.white)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(.white.opacity(0.06))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(isMatch ? AdKanTheme.brandGreen.opacity(0.6) : .white.opacity(0.12), lineWidth: 1)
                                )
                        )
                        .offset(x: shake ? -8 : 0)
                        .onSubmit { attemptUnlock() }
                }
                .padding(.horizontal, AdKanTheme.screenPadding)
                .opacity(animateIn ? 1 : 0)

                Button(action: attemptUnlock) {
                    Text("hardMode.friction.submit")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: AdKanTheme.buttonCornerRadius)
                                .fill(isMatch ? AdKanTheme.brandGreen : .white.opacity(0.12))
                        )
                        .animation(.easeInOut(duration: 0.25), value: isMatch)
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

    private func attemptUnlock() {
        if isMatch {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            onComplete()
        } else {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            withAnimation(.spring(response: 0.1, dampingFraction: 0.3)) {
                shake = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                shake = false
            }
        }
    }
}
