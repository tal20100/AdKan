// Per-app screen-time blocking UI with real ManagedSettings enforcement.
import SwiftUI
#if canImport(FamilyControls)
import FamilyControls
#endif

// MARK: - View

struct BlockingView: View {
    @AppStorage("blockingEnabled") private var blockingEnabled = false
    @EnvironmentObject private var ruleStore: BlockingRuleStore
    @EnvironmentObject private var storeManager: StoreManager
    @EnvironmentObject private var languageManager: LanguageManager

    @State private var showTimeRuleEditor = false
    @State private var editingTimeRule: TimeBlockRule?
    @State private var editingDaySchedule: DayScheduleRule?
    @State private var showHardModePreview = false
    @State private var showAppPicker = false
    #if canImport(FamilyControls)
    @State private var activitySelection = FamilyActivitySelection()
    #endif
    @StateObject private var enforcer = BlockingEnforcer.shared

    @AppStorage("hardModeConfigJSON") private var hardModeConfigJSON: String = ""

    private var hardModeConfig: HardModeConfig {
        guard let data = hardModeConfigJSON.data(using: .utf8),
              let config = try? JSONDecoder().decode(HardModeConfig.self, from: data)
        else { return HardModeConfig() }
        return config
    }

    var body: some View {
        NavigationStack {
            List {
                heroSection
                masterToggleSection
                if blockingEnabled {
                    realAppPickerSection
                    timeBlockSection
                    dayScheduleSection
                    globalLimitSection
                    hardModeSection
                    shieldCustomizationSection
                    entitlementSection
                }
            }
            .navigationTitle(Text("blocking.title"))
            .animation(.easeInOut(duration: 0.25), value: blockingEnabled)
            .onAppear {
                #if canImport(FamilyControls)
                if let saved = enforcer.loadSavedSelection() {
                    activitySelection = saved
                }
                #endif
            }
            .onChange(of: blockingEnabled) { _, enabled in
                if !enabled {
                    enforcer.removeAllShields()
                }
            }
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
            GradientCard(gradient: AdKanTheme.primaryGradient) {
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

    private var realAppPickerSection: some View {
        Section {
            #if canImport(FamilyControls)
            Button {
                showAppPicker = true
            } label: {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("blocking.selectApps")
                            .font(.body.weight(.medium))
                        let count = activitySelection.applicationTokens.count + activitySelection.categoryTokens.count
                        if count > 0 {
                            Text("blocking.selectedCount \(count)")
                                .font(.caption)
                                .foregroundStyle(AdKanTheme.primary)
                        }
                    }
                } icon: {
                    Image(systemName: "apps.iphone")
                        .foregroundStyle(AdKanTheme.primary)
                }
            }
            .foregroundStyle(.primary)
            .familyActivityPicker(isPresented: $showAppPicker, selection: $activitySelection)
            .onChange(of: activitySelection) { _, newSelection in
                enforcer.applyShields(for: newSelection)
                SharedDefaults.shieldIsPremium = storeManager.isPremium
            }
            #else
            Label {
                Text("blocking.selectApps.simulator")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } icon: {
                Image(systemName: "apps.iphone")
                    .foregroundStyle(.secondary)
            }
            #endif
        } header: {
            Text("blocking.selectApps.header")
        } footer: {
            Text("blocking.selectApps.footer")
                .font(.caption)
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
            ForEach(ruleStore.dayScheduleRules) { schedule in
                dayScheduleRow(schedule)
            }
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

    // MARK: - Shield Customization

    private var shieldCustomizationSection: some View {
        Section {
            Group {
                NavigationLink {
                    ShieldCustomizationView()
                } label: {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("blocking.customizeShield")
                                .font(.body.weight(.medium))
                            Text("blocking.customizeShield.desc")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "shield.checkered")
                            .foregroundStyle(AdKanTheme.brandPurple)
                    }
                }
            }
            .premiumGated(.customShieldDesign)
        } header: {
            Text("blocking.customizeShield.header")
        }
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

    // MARK: - Formatting

    private func formattedLimit(_ minutes: Int) -> String {
        TimeFormatter.format(minutes: minutes, locale: languageManager.preferredLanguage)
    }
}
