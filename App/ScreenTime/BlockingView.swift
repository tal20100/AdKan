// Per-app screen-time blocking UI; FamilyActivityPicker integration point marked below.
import SwiftUI

// MARK: - Model

struct BlockableApp: Codable, Identifiable, Hashable {
    let id: String
    let nameKey: String
    let icon: String
    var isBlocked: Bool
    var customLimitMinutes: Int?

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: BlockableApp, rhs: BlockableApp) -> Bool { lhs.id == rhs.id }
}

// MARK: - Default app catalogue

private extension BlockableApp {
    static let catalogue: [BlockableApp] = [
        BlockableApp(id: "tiktok",    nameKey: "blocking.app.tiktok",    icon: "🎵", isBlocked: false),
        BlockableApp(id: "instagram", nameKey: "blocking.app.instagram", icon: "📸", isBlocked: false),
        BlockableApp(id: "youtube",   nameKey: "blocking.app.youtube",   icon: "▶️", isBlocked: false),
        BlockableApp(id: "whatsapp",  nameKey: "blocking.app.whatsapp",  icon: "💬", isBlocked: false),
        BlockableApp(id: "snapchat",  nameKey: "blocking.app.snapchat",  icon: "👻", isBlocked: false),
        BlockableApp(id: "x",         nameKey: "blocking.app.x",         icon: "🐦", isBlocked: false),
        BlockableApp(id: "telegram",  nameKey: "blocking.app.telegram",  icon: "✈️", isBlocked: false),
        BlockableApp(id: "facebook",  nameKey: "blocking.app.facebook",  icon: "👤", isBlocked: false),
        BlockableApp(id: "reddit",    nameKey: "blocking.app.reddit",    icon: "🤖", isBlocked: false),
        BlockableApp(id: "netflix",   nameKey: "blocking.app.netflix",   icon: "🎬", isBlocked: false),
    ]
}

// MARK: - AppStorage codec

private enum AppsStorage {
    static func decode(_ raw: String) -> [BlockableApp] {
        guard
            let data = raw.data(using: .utf8),
            let decoded = try? JSONDecoder().decode([BlockableApp].self, from: data)
        else { return BlockableApp.catalogue }
        return decoded
    }

    static func encode(_ apps: [BlockableApp]) -> String {
        guard
            let data = try? JSONEncoder().encode(apps),
            let str = String(data: data, encoding: .utf8)
        else { return "" }
        return str
    }
}

// MARK: - View

struct BlockingView: View {
    @AppStorage("blockingEnabled") private var blockingEnabled = false
    @AppStorage("defaultLimitMinutes") private var defaultLimitMinutes: Int = 120
    @AppStorage("blockedAppsJSON") private var blockedAppsJSON: String = ""

    @State private var apps: [BlockableApp] = []
    @State private var expandedAppID: String? = nil

    private var blockedCount: Int { apps.filter(\.isBlocked).count }

    var body: some View {
        NavigationStack {
            List {
                heroSection
                masterToggleSection
                if blockingEnabled {
                    defaultLimitSection
                    appsSection
                    entitlementSection
                }
            }
            .navigationTitle(Text("blocking.title"))
            .animation(.easeInOut(duration: 0.25), value: blockingEnabled)
            .onAppear { loadApps() }
        }
    }

    // MARK: - Sections

    private var heroSection: some View {
        Section {
            GradientCard {
                VStack(spacing: 12) {
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 40))
                        .foregroundStyle(.white)

                    Text("blocking.hero.title")
                        .font(AdKanTheme.cardTitle)
                        .foregroundStyle(.white)

                    Text("blocking.hero.body")
                        .font(AdKanTheme.cardBody)
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        }
    }

    private var masterToggleSection: some View {
        Section {
            Toggle(isOn: $blockingEnabled) {
                Label {
                    Text("blocking.toggle")
                } icon: {
                    Image(systemName: "shield.checkered")
                        .foregroundStyle(blockingEnabled ? AdKanTheme.successGreen : .secondary)
                }
            }
            .tint(AdKanTheme.successGreen)
        } footer: {
            Text("blocking.toggle.footer")
                .font(.caption)
        }
    }

    private var defaultLimitSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                LabeledContent {
                    Text(formattedLimit(defaultLimitMinutes))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AdKanTheme.primary)
                } label: {
                    Text("blocking.defaultLimit.label")
                        .font(.subheadline.weight(.medium))
                }

                Slider(
                    value: Binding(
                        get: { Double(defaultLimitMinutes) },
                        set: { defaultLimitMinutes = Int($0) }
                    ),
                    in: 15...480,
                    step: 15
                )
                .tint(AdKanTheme.primary)

                HStack {
                    Text("15m")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Spacer()
                    Text("8h")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        } header: {
            Text("blocking.defaultLimit.header")
        } footer: {
            Text("blocking.defaultLimit.footer")
                .font(.caption)
        }
    }

    private var appsSection: some View {
        Section {
            ForEach(apps.indices, id: \.self) { index in
                appRow(index: index)
            }
        } header: {
            HStack {
                Text("blocking.apps.header")
                Spacer()
                if blockedCount > 0 {
                    Text("blocking.apps.blockedCount \(blockedCount)")
                        .font(.caption)
                        .foregroundStyle(AdKanTheme.primary)
                }
            }
        }
    }

    @ViewBuilder
    private func appRow(index: Int) -> some View {
        let app = apps[index]
        let isExpanded = expandedAppID == app.id

        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Text(app.icon)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(LocalizedStringKey(app.nameKey))
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)

                    if app.isBlocked {
                        let limit = app.customLimitMinutes ?? defaultLimitMinutes
                        Text("blocking.app.activeLimit \(formattedLimit(limit))")
                            .font(.caption)
                            .foregroundStyle(AdKanTheme.primary)
                    }
                }

                Spacer()

                if app.isBlocked {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            expandedAppID = isExpanded ? nil : app.id
                        }
                    } label: {
                        Image(systemName: isExpanded ? "chevron.up.circle" : "slider.horizontal.3")
                            .foregroundStyle(AdKanTheme.primary)
                            .font(.body)
                    }
                    .buttonStyle(.plain)
                }

                Toggle("", isOn: Binding(
                    get: { apps[index].isBlocked },
                    set: { newVal in
                        apps[index].isBlocked = newVal
                        if !newVal {
                            apps[index].customLimitMinutes = nil
                            if expandedAppID == app.id { expandedAppID = nil }
                        }
                        saveApps()
                    }
                ))
                .labelsHidden()
                .tint(AdKanTheme.successGreen)
            }
            .padding(.vertical, 4)

            if isExpanded {
                perAppLimitSlider(index: index)
                    .padding(.top, 10)
                    .padding(.bottom, 4)
            }
        }
    }

    private func perAppLimitSlider(index: Int) -> some View {
        let currentLimit = apps[index].customLimitMinutes ?? defaultLimitMinutes

        return VStack(alignment: .leading, spacing: 8) {
            Divider()

            LabeledContent {
                Text(formattedLimit(currentLimit))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AdKanTheme.primary)
            } label: {
                Text("blocking.app.customLimit.label")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Slider(
                value: Binding(
                    get: { Double(currentLimit) },
                    set: { newVal in
                        apps[index].customLimitMinutes = Int(newVal)
                        saveApps()
                    }
                ),
                in: 15...480,
                step: 15
            )
            .tint(AdKanTheme.primary)

            HStack {
                Button("blocking.app.customLimit.useDefault") {
                    apps[index].customLimitMinutes = nil
                    saveApps()
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .buttonStyle(.plain)

                Spacer()

                HStack(spacing: 4) {
                    Text("15m")
                    Text("–")
                    Text("8h")
                }
                .font(.caption2)
                .foregroundStyle(.tertiary)
            }
        }
    }

    // FUTURE: FamilyActivityPicker integration goes here.
    // When FamilyControls entitlement is active, replace the simulated toggles
    // with FamilyActivityPicker. Map selections to ManagedSettingsStore via
    // RealScreenTimeProvider (the only file allowed to import FamilyControls,
    // per ADR 0005).
    private var entitlementSection: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(AdKanTheme.warningOrange)
                Text("blocking.entitlement.notice")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Persistence

    private func loadApps() {
        if blockedAppsJSON.isEmpty {
            apps = BlockableApp.catalogue
        } else {
            apps = AppsStorage.decode(blockedAppsJSON)
        }
    }

    private func saveApps() {
        blockedAppsJSON = AppsStorage.encode(apps)
    }

    // MARK: - Formatting

    private func formattedLimit(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        if h == 0 { return "\(m)m" }
        if m == 0 { return "\(h)h" }
        return "\(h)h \(m)m"
    }
}
