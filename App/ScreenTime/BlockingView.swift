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
    @EnvironmentObject private var ruleStore: BlockingRuleStore
    @EnvironmentObject private var storeManager: StoreManager

    @State private var apps: [BlockableApp] = []
    @State private var expandedAppID: String? = nil
    @State private var showTimeRuleEditor = false
    @State private var editingTimeRule: TimeBlockRule?
    @State private var editingDaySchedule: DayScheduleRule?
    @State private var showHardModePreview = false

    @AppStorage("hardModeConfigJSON") private var hardModeConfigJSON: String = ""

    private var hardModeConfig: HardModeConfig {
        guard let data = hardModeConfigJSON.data(using: .utf8),
              let config = try? JSONDecoder().decode(HardModeConfig.self, from: data)
        else { return HardModeConfig() }
        return config
    }

    private var blockedCount: Int { apps.filter(\.isBlocked).count }

    var body: some View {
        NavigationStack {
            List {
                heroSection
                masterToggleSection
                if blockingEnabled {
                    defaultLimitSection
                    appsSection
                    timeBlockSection
                    dayScheduleSection
                    globalLimitSection
                    hardModeSection
                    entitlementSection
                }
            }
            .navigationTitle(Text("blocking.title"))
            .animation(.easeInOut(duration: 0.25), value: blockingEnabled)
            .onAppear { loadApps() }
            .sheet(isPresented: $showTimeRuleEditor) {
                TimeBlockRuleEditor(editingRule: editingTimeRule)
            }
            .sheet(item: $editingDaySchedule) { schedule in
                DayScheduleEditor(rule: schedule)
            }
            .fullScreenCover(isPresented: $showHardModePreview) {
                HardModeCoordinator(config: hardModeConfig) {
                    showHardModePreview = false
                }
            }
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
            ForEach(Array(apps.enumerated()), id: \.element.id) { index, _ in
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
                    .buttonStyle(.borderless)
                }

                Toggle("", isOn: appBlockedBinding(index: index))
                .labelsHidden()
                .tint(AdKanTheme.successGreen)
                .buttonStyle(.borderless)
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

    // MARK: - Time Block Rules

    private var timeBlockSection: some View {
        Section {
            Group {
                if ruleStore.timeBlockRules.isEmpty {
                    HStack(spacing: 12) {
                        Image(systemName: "clock.badge.xmark")
                            .font(.title3)
                            .foregroundStyle(AdKanTheme.brandPurple)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("blocking.timeRule.empty.title")
                                .font(.subheadline.weight(.medium))
                            Text("blocking.timeRule.empty.body")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                } else {
                    ForEach(ruleStore.timeBlockRules) { rule in
                        timeBlockRuleRow(rule)
                    }
                    .onDelete { offsets in
                        ruleStore.removeTimeBlockRule(at: offsets)
                    }
                }

                Button {
                    editingTimeRule = nil
                    showTimeRuleEditor = true
                } label: {
                    Label("blocking.timeRule.add", systemImage: "plus.circle.fill")
                        .foregroundStyle(AdKanTheme.primary)
                }
            }
            .premiumGated(.timeBasedBlocking)
        } header: {
            Text("blocking.timeRule.header")
        } footer: {
            Text("blocking.timeRule.footer")
                .font(.caption)
        }
    }

    private func timeBlockRuleRow(_ rule: TimeBlockRule) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(rule.label)
                    .font(.body.weight(.medium))
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text("\(rule.startTimeString) – \(rule.endTimeString)")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { rule.isEnabled },
                set: { newVal in
                    var updated = rule
                    updated.isEnabled = newVal
                    ruleStore.updateTimeBlockRule(updated)
                }
            ))
            .labelsHidden()
            .tint(AdKanTheme.successGreen)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .onTapGesture {
            editingTimeRule = rule
            showTimeRuleEditor = true
        }
    }

    // MARK: - Day Schedule

    private var dayScheduleSection: some View {
        Section {
            Group {
                ForEach(ruleStore.dayScheduleRules) { schedule in
                    dayScheduleRow(schedule)
                }
            }
            .premiumGated(.timeBasedBlocking)
        } header: {
            Text("blocking.schedule.header")
        } footer: {
            Text("blocking.schedule.footer")
                .font(.caption)
        }
    }

    private func dayScheduleRow(_ schedule: DayScheduleRule) -> some View {
        HStack(spacing: 12) {
            Image(systemName: schedule.activeDays.count <= 2 ? "sun.max.fill" : "briefcase.fill")
                .font(.title3)
                .foregroundStyle(schedule.isEnabled ? AdKanTheme.primary : .secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey(schedule.name))
                    .font(.body.weight(.medium))
                Text("blocking.schedule.limitLabel \(formattedLimit(schedule.defaultLimitMinutes))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 8) {
                Button {
                    editingDaySchedule = schedule
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundStyle(AdKanTheme.primary)
                }
                .buttonStyle(.plain)

                Toggle("", isOn: Binding(
                    get: { schedule.isEnabled },
                    set: { _ in ruleStore.toggleDaySchedule(schedule) }
                ))
                .labelsHidden()
                .tint(AdKanTheme.successGreen)
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: - Global Limit

    private var globalLimitSection: some View {
        Section {
            Group {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle(isOn: Binding(
                        get: { ruleStore.globalLimitRule.isEnabled },
                        set: { newVal in
                            var updated = ruleStore.globalLimitRule
                            updated.isEnabled = newVal
                            ruleStore.updateGlobalLimit(updated)
                        }
                    )) {
                        Label {
                            Text("blocking.global.toggle")
                        } icon: {
                            Image(systemName: "gauge.with.dots.needle.67percent")
                                .foregroundStyle(ruleStore.globalLimitRule.isEnabled ? AdKanTheme.warningOrange : .secondary)
                        }
                    }
                    .tint(AdKanTheme.successGreen)

                    if ruleStore.globalLimitRule.isEnabled {
                        VStack(alignment: .leading, spacing: 8) {
                            LabeledContent {
                                Text(formattedLimit(ruleStore.globalLimitRule.thresholdMinutes))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AdKanTheme.warningOrange)
                            } label: {
                                Text("blocking.global.threshold")
                                    .font(.subheadline)
                            }

                            Slider(
                                value: Binding(
                                    get: { Double(ruleStore.globalLimitRule.thresholdMinutes) },
                                    set: {
                                        var updated = ruleStore.globalLimitRule
                                        updated.thresholdMinutes = Int($0)
                                        ruleStore.updateGlobalLimit(updated)
                                    }
                                ),
                                in: 60...480,
                                step: 15
                            )
                            .tint(AdKanTheme.warningOrange)
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
            .premiumGated(.globalLimitRule)
        } header: {
            Text("blocking.global.header")
        } footer: {
            Text("blocking.global.footer")
                .font(.caption)
        }
    }

    // MARK: - Hard Mode

    private var hardModeSection: some View {
        Section {
            Group {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle(isOn: Binding(
                        get: { hardModeConfig.isEnabled },
                        set: { newVal in
                            saveHardModeConfig(HardModeConfig(
                                isEnabled: newVal,
                                unlockDelaySeconds: hardModeConfig.unlockDelaySeconds,
                                mentalGateEnabled: hardModeConfig.mentalGateEnabled,
                                frictionPhraseEnabled: hardModeConfig.frictionPhraseEnabled
                            ))
                        }
                    )) {
                        Label {
                            Text("blocking.hardMode.toggle")
                        } icon: {
                            Image(systemName: "hand.raised.fill")
                                .foregroundStyle(hardModeConfig.isEnabled ? AdKanTheme.dangerRed : .secondary)
                        }
                    }
                    .tint(AdKanTheme.dangerRed)

                    if hardModeConfig.isEnabled {
                        VStack(alignment: .leading, spacing: 14) {
                            VStack(alignment: .leading, spacing: 6) {
                                LabeledContent {
                                    Text("\(hardModeConfig.unlockDelaySeconds)s")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(AdKanTheme.dangerRed)
                                } label: {
                                    Text("blocking.hardMode.delay")
                                        .font(.subheadline)
                                }

                                Slider(
                                    value: Binding(
                                        get: { Double(hardModeConfig.unlockDelaySeconds) },
                                        set: { newVal in
                                            saveHardModeConfig(HardModeConfig(
                                                isEnabled: true,
                                                unlockDelaySeconds: Int(newVal),
                                                mentalGateEnabled: hardModeConfig.mentalGateEnabled,
                                                frictionPhraseEnabled: hardModeConfig.frictionPhraseEnabled
                                            ))
                                        }
                                    ),
                                    in: 10...60,
                                    step: 5
                                )
                                .tint(AdKanTheme.dangerRed)
                            }

                            Toggle("blocking.hardMode.mentalGate", isOn: Binding(
                                get: { hardModeConfig.mentalGateEnabled },
                                set: { newVal in
                                    saveHardModeConfig(HardModeConfig(
                                        isEnabled: true,
                                        unlockDelaySeconds: hardModeConfig.unlockDelaySeconds,
                                        mentalGateEnabled: newVal,
                                        frictionPhraseEnabled: hardModeConfig.frictionPhraseEnabled
                                    ))
                                }
                            ))
                            .tint(AdKanTheme.dangerRed)

                            Toggle("blocking.hardMode.frictionPhrase", isOn: Binding(
                                get: { hardModeConfig.frictionPhraseEnabled },
                                set: { newVal in
                                    saveHardModeConfig(HardModeConfig(
                                        isEnabled: true,
                                        unlockDelaySeconds: hardModeConfig.unlockDelaySeconds,
                                        mentalGateEnabled: hardModeConfig.mentalGateEnabled,
                                        frictionPhraseEnabled: newVal
                                    ))
                                }
                            ))
                            .tint(AdKanTheme.dangerRed)

                            Button {
                                showHardModePreview = true
                            } label: {
                                Label("blocking.hardMode.preview", systemImage: "play.circle.fill")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(AdKanTheme.dangerRed)
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
            .premiumGated(.hardMode)
        } header: {
            Text("blocking.hardMode.header")
        } footer: {
            Text("blocking.hardMode.footer")
                .font(.caption)
        }
    }

    private func saveHardModeConfig(_ config: HardModeConfig) {
        guard let data = try? JSONEncoder().encode(config),
              let str = String(data: data, encoding: .utf8)
        else { return }
        hardModeConfigJSON = str
    }

    // MARK: - Entitlement Notice

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

    // MARK: - Bindings

    private func appBlockedBinding(index: Int) -> Binding<Bool> {
        Binding(
            get: { guard index < apps.count else { return false }; return apps[index].isBlocked },
            set: { newVal in
                guard index < apps.count else { return }
                var updated = apps
                updated[index].isBlocked = newVal
                if !newVal {
                    updated[index].customLimitMinutes = nil
                    if expandedAppID == updated[index].id { expandedAppID = nil }
                }
                apps = updated
                saveApps()
            }
        )
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
