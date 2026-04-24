import SwiftUI

struct SettingsView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @AppStorage("dailyGoalMinutes") private var goalMinutes: Int = 120
    @EnvironmentObject private var languageManager: LanguageManager
    @EnvironmentObject private var services: ServiceContainer
    @State private var showPaywall = false
    @State private var showSignOutConfirm = false
    @State private var showDeleteConfirm = false

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
                    Link(destination: URL(string: "https://taltalhayun.com/adkan/privacy")!) {
                        Label {
                            Text("settings.privacyPolicy")
                        } icon: {
                            Image(systemName: "lock.shield.fill")
                                .foregroundStyle(AdKanTheme.successGreen)
                        }
                    }
                    .foregroundStyle(.primary)

                    Link(destination: URL(string: "https://taltalhayun.com/adkan/terms")!) {
                        Label {
                            Text("settings.termsOfService")
                        } icon: {
                            Image(systemName: "doc.text.fill")
                                .foregroundStyle(AdKanTheme.primary)
                        }
                    }
                    .foregroundStyle(.primary)

                    Link(destination: URL(string: "mailto:tal.hayun2010@gmail.com")!) {
                        Label {
                            Text("settings.contact")
                        } icon: {
                            Image(systemName: "envelope.fill")
                                .foregroundStyle(AdKanTheme.primary)
                        }
                    }
                    .foregroundStyle(.primary)
                }

                Section {
                    Button(action: { showSignOutConfirm = true }) {
                        Label {
                            Text("settings.signOut")
                        } icon: {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundStyle(.orange)
                        }
                    }
                    .foregroundStyle(.primary)

                    Button(role: .destructive, action: { showDeleteConfirm = true }) {
                        Label {
                            Text("settings.deleteAccount")
                        } icon: {
                            Image(systemName: "trash.fill")
                        }
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
            .alert("settings.signOut.confirm", isPresented: $showSignOutConfirm) {
                Button("settings.signOut", role: .destructive) {
                    services.auth.signOut()
                    hasCompletedOnboarding = false
                }
                Button("common.cancel", role: .cancel) {}
            }
            .alert("settings.deleteAccount.confirm", isPresented: $showDeleteConfirm) {
                Button("settings.deleteAccount", role: .destructive) {
                    services.auth.signOut()
                    clearAllData()
                    hasCompletedOnboarding = false
                }
                Button("common.cancel", role: .cancel) {}
            } message: {
                Text("settings.deleteAccount.message")
            }
        }
    }

    private func clearAllData() {
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
    }
}
