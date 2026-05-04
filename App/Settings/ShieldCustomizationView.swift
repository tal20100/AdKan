import SwiftUI

struct ShieldCustomizationView: View {
    @State private var title: String = SharedDefaults.shieldTitle
    @State private var subtitle: String = SharedDefaults.shieldSubtitle
    @State private var selectedTheme: Int = SharedDefaults.shieldThemeIndex

    private let themes: [(name: String, key: String)] = [
        ("Default", "shield.theme.default"),
        ("Forest", "shield.theme.forest"),
        ("Purple", "shield.theme.purple"),
        ("Midnight", "shield.theme.midnight"),
    ]

    var body: some View {
        List {
            Section {
                shieldPreview
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
            }

            Section("shield.customize.titleField") {
                TextField("shield.customize.titlePlaceholder", text: $title)
                    .onChange(of: title) { _, newVal in
                        SharedDefaults.shieldTitle = newVal
                    }
            }

            Section("shield.customize.subtitleField") {
                TextField("shield.customize.subtitlePlaceholder", text: $subtitle)
                    .onChange(of: subtitle) { _, newVal in
                        SharedDefaults.shieldSubtitle = newVal
                    }
            }

            Section("shield.customize.theme") {
                ForEach(Array(themes.enumerated()), id: \.offset) { index, theme in
                    Button {
                        selectedTheme = index
                        SharedDefaults.shieldThemeIndex = index
                    } label: {
                        HStack {
                            Circle()
                                .fill(themeColor(index))
                                .frame(width: 24, height: 24)
                            Text(LocalizedStringKey(theme.key))
                                .foregroundStyle(.primary)
                            Spacer()
                            if selectedTheme == index {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(AdKanTheme.primary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(Text("shield.customize.title"))
    }

    private var shieldPreview: some View {
        VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 20)
                .fill(previewBackground)
                .frame(height: 200)
                .overlay {
                    VStack(spacing: 12) {
                        Image(systemName: "shield.checkered")
                            .font(.system(size: 32))
                            .foregroundStyle(.white.opacity(0.5))

                        Text(title.isEmpty ? "עד כאן" : title)
                            .font(.title3.bold())
                            .foregroundStyle(.white)

                        Text(subtitle.isEmpty ? "Stay strong!" : subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)

                        HStack(spacing: 12) {
                            Text("shield.button.close")
                                .font(.subheadline.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(previewAccent)
                                .clipShape(Capsule())

                            Text("shield.button.allowOneMin")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        }
    }

    private var previewBackground: LinearGradient {
        let base = themeColor(selectedTheme)
        return LinearGradient(
            colors: [base.opacity(0.9), base],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var previewAccent: Color {
        switch selectedTheme {
        case 1: return Color(red: 0.2, green: 0.78, blue: 0.35)
        case 2: return Color(red: 0.69, green: 0.32, blue: 0.87)
        case 3: return Color(red: 0.3, green: 0.5, blue: 0.9)
        default: return Color(red: 0.2, green: 0.55, blue: 0.4)
        }
    }

    private func themeColor(_ index: Int) -> Color {
        switch index {
        case 1: return Color(red: 0.06, green: 0.14, blue: 0.1)
        case 2: return Color(red: 0.1, green: 0.05, blue: 0.15)
        case 3: return Color(red: 0.02, green: 0.02, blue: 0.08)
        default: return Color(red: 0.05, green: 0.05, blue: 0.12)
        }
    }
}
