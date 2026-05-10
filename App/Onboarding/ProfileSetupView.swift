import SwiftUI

struct ProfileSetupView: View {
    @EnvironmentObject private var services: ServiceContainer
    @EnvironmentObject private var languageManager: LanguageManager
    @AppStorage("profileDisplayName") private var savedDisplayName = ""
    @AppStorage("profileAvatarEmoji") private var savedAvatarEmoji = ""
    @State private var displayName = ""
    @State private var selectedEmoji = ""
    @State private var isSaving = false
    var onComplete: (() -> Void)?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 8)

    static let curatedEmojis: [String] = [
        "😎", "🤓", "😊", "🥳", "😈", "🤩", "😤", "🧐",
        "🦄", "🐱", "🐶", "🦊", "🐻", "🐼", "🐸", "🦋",
        "🌸", "🌺", "🌻", "🍀", "🌙", "⭐️", "🔥", "💎",
        "🎯", "🏆", "⚡️", "🎮", "🎸", "🎨", "📚", "💪",
        "🍕", "🍩", "☕️", "🧋", "🫶", "✌️", "🤙", "👑"
    ]

    private var isValid: Bool {
        !displayName.trimmingCharacters(in: .whitespaces).isEmpty && !selectedEmoji.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 28) {
                    header
                    avatarPreview
                    nameField
                    emojiGrid
                }
                .padding(.horizontal, AdKanTheme.screenPadding)
                .padding(.top, 24)
                .padding(.bottom, 100)
            }

            saveButton
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .onAppear {
            if !savedDisplayName.isEmpty { displayName = savedDisplayName }
            if !savedAvatarEmoji.isEmpty {
                selectedEmoji = savedAvatarEmoji
            } else {
                selectedEmoji = Self.curatedEmojis.randomElement() ?? "😎"
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text("profile.setup.title")
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            Text("profile.setup.subtitle")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var avatarPreview: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(AdKanTheme.brandGreen.opacity(0.12))
                    .frame(width: 100, height: 100)

                Text(selectedEmoji)
                    .font(.system(size: 52))
            }

            if !displayName.trimmingCharacters(in: .whitespaces).isEmpty {
                Text(displayName.trimmingCharacters(in: .whitespaces))
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
        }
        .animation(.spring(response: 0.3), value: selectedEmoji)
        .animation(.spring(response: 0.3), value: displayName)
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("profile.setup.nameLabel")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)

            TextField(
                String(localized: "profile.setup.namePlaceholder"),
                text: $displayName
            )
            .font(.body)
            .padding(14)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .onChange(of: displayName) { _, newValue in
                if newValue.count > 20 {
                    displayName = String(newValue.prefix(20))
                }
            }
        }
    }

    private var emojiGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("profile.setup.emojiLabel")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(Self.curatedEmojis, id: \.self) { emoji in
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        selectedEmoji = emoji
                    } label: {
                        Text(emoji)
                            .font(.system(size: 28))
                            .frame(width: 44, height: 44)
                            .background(
                                selectedEmoji == emoji
                                    ? AdKanTheme.brandGreen.opacity(0.2)
                                    : Color(.tertiarySystemBackground)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(
                                        selectedEmoji == emoji ? AdKanTheme.brandGreen : .clear,
                                        lineWidth: 2
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var saveButton: some View {
        VStack {
            AdKanButton(
                titleKey: onComplete != nil ? "profile.setup.continue" : "profile.setup.save",
                style: .primary
            ) {
                save()
            }
            .disabled(!isValid || isSaving)
            .opacity(isValid ? 1 : 0.5)
        }
        .padding(.horizontal, AdKanTheme.screenPadding)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    private func save() {
        let trimmed = displayName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !selectedEmoji.isEmpty else { return }

        isSaving = true
        savedDisplayName = trimmed
        savedAvatarEmoji = selectedEmoji

        Task {
            try? await services.auth.updateProfile(
                displayName: trimmed,
                avatarEmoji: selectedEmoji
            )
            isSaving = false
            onComplete?()
        }
    }
}
