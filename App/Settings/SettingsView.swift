import SwiftUI

struct SettingsView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @AppStorage("dailyGoalMinutes") private var goalMinutes: Int = 120
    @State private var showPaywall = false
    @State private var showBlocking = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Label {
                            Text("Daily goal")
                        } icon: {
                            Image(systemName: "target")
                                .foregroundStyle(AdKanTheme.primary)
                        }
                        Spacer()
                        Picker("", selection: $goalMinutes) {
                            Text("1h").tag(60)
                            Text("1.5h").tag(90)
                            Text("2h").tag(120)
                            Text("3h").tag(180)
                        }
                        .pickerStyle(.menu)
                    }
                }

                Section {
                    Button(action: { showBlocking = true }) {
                        Label {
                            Text("blocking.title")
                        } icon: {
                            Image(systemName: "shield.checkered")
                                .foregroundStyle(AdKanTheme.primary)
                        }
                    }
                    .foregroundStyle(.primary)
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
                    HStack {
                        Text("Version")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .navigationTitle(Text("settings.title"))
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showBlocking) {
                BlockSettingsView()
            }
        }
    }
}
