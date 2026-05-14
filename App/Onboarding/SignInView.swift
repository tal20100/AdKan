import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @EnvironmentObject private var services: ServiceContainer
    @EnvironmentObject private var languageManager: LanguageManager
    @AppStorage("authSkipped") private var authSkipped = false
    @State private var isSigningIn = false
    @State private var errorMessage: String?
    var onComplete: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(AdKanTheme.primary.opacity(0.12))
                    .frame(width: 100, height: 100)

                Image(systemName: "person.crop.circle.badge.checkmark")
                    .font(.system(size: 44))
                    .foregroundStyle(AdKanTheme.primary)
            }

            VStack(spacing: 12) {
                Text("signin.title")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)

                Text("signin.body")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            VStack(spacing: 16) {
                SignInWithAppleButton(
                    .signIn,
                    onRequest: { request in
                        request.requestedScopes = [.fullName]
                    },
                    onCompletion: { result in
                        handleSignIn(result: result)
                    }
                )
                .signInWithAppleButtonStyle(
                    languageManager.preferredLanguage == "he" ? .black : .black
                )
                .frame(height: 50)
                .clipShape(RoundedRectangle(cornerRadius: AdKanTheme.buttonCornerRadius))
                .disabled(isSigningIn)

                if isSigningIn {
                    ProgressView()
                }

                Button {
                    authSkipped = true
                    onComplete()
                } label: {
                    Text("signin.skip")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, AdKanTheme.screenPadding)
            .padding(.bottom, 48)
        }
        .alert("common.error", isPresented: .init(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("common.ok") { errorMessage = nil }
        } message: {
            if let msg = errorMessage {
                Text(msg)
            }
        }
    }

    private func handleSignIn(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else {
                errorMessage = NSLocalizedString("signin.error.generic", comment: "")
                return
            }
            isSigningIn = true
            Task {
                do {
                    try await services.auth.signInWithApple(credential: credential)
                    onComplete()
                } catch {
                    errorMessage = error.localizedDescription
                }
                isSigningIn = false
            }
        case .failure(let error):
            if (error as NSError).code == ASAuthorizationError.canceled.rawValue {
                return
            }
            errorMessage = error.localizedDescription
        }
    }
}
