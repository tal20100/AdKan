import SwiftUI

struct SettingsView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @AppStorage("dailyGoalMinutes") private var goalMinutes: Int = 120
    @EnvironmentObject private var languageManager: LanguageManager
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent {
                        Picker("", selection: $languageManager.preferredLanguage) {
                            Text("עברית").tag("he")
                            Text("English").tag("en")
                        }
                        .pickerStyle(.menu)
                    } label: {
                        Label {
                            Text("settings.language")
                        } icon: {
                            Image(systemName: "globe")
                                .foregroundStyle(AdKanTheme.primary)
                        }
                    }
                }

                Section {
                    LabeledContent {
                        Picker("", selection: $goalMinutes) {
                            Text("1h").tag(60)
                            Text("1.5h").tag(90)
                            Text("2h").tag(120)
                            Text("3h").tag(180)
                        }
                        .pickerStyle(.menu)
                    } label: {
                        Label {
                            Text("settings.dailyGoal")
                        } icon: {
                            Image(systemName: "target")
                                .foregroundStyle(AdKanTheme.primary)
                        }
                    }
                }

                Section {
                    Button(action: { hasCompletedOnboarding = false }) {
                        Label {
                            Text("settings.retakeSurvey")
                        } icon: {
                            Image(systemName: "arrow.counterclockwise")
                                .foregroundStyle(AdKanTheme.primary)
                        }
                    }
                    .foregroundStyle(.primary)

                    Button(action: { showPaywall = true }) {
                        Label {
                            Text("paywall.hero.title")
                        } icon: {
                            Image(systemName: "crown.fill")
                                .foregroundStyle(.yellow)
                        }
                    }
                    .foregroundStyle(.primary)
                }

                Section {
                    Label {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("settings.privacy")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "lock.shield.fill")
                            .foregroundStyle(AdKanTheme.successGreen)
                    }
                }

                Section {
                    LabeledContent {
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                            .foregroundStyle(.tertiary)
                    } label: {
                        Text("settings.version")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(Text("settings.title"))
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }
}
