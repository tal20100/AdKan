import SwiftUI
import UserNotifications

struct SettingsView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @AppStorage("dailyGoalMinutes") private var goalMinutes: Int = 120
    @EnvironmentObject private var languageManager: LanguageManager
    @EnvironmentObject private var services: ServiceContainer
    @EnvironmentObject private var storeManager: StoreManager
    @State private var showPaywall = false
    @State private var showSignOutConfirm = false
    @State private var showDeleteConfirm = false
    @AppStorage("eveningReminderEnabled") private var eveningReminder = false
    @AppStorage("weeklyCheckinEnabled") private var weeklyCheckin = true

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

                Section("settings.notifications") {
                    Toggle(isOn: $eveningReminder) {
                        Label {
                            Text("settings.notifications.evening")
                        } icon: {
                            Image(systemName: "moon.fill")
                                .foregroundStyle(.purple)
                        }
                    }
                    .tint(AdKanTheme.primary)
                    .onChange(of: eveningReminder) { _, enabled in
                        Task {
                            if enabled {
                                let granted = await NotificationManager.shared.requestPermission()
                                if granted {
                                    NotificationManager.shared.scheduleEveningReminder()
                                } else {
                                    eveningReminder = false
                                }
                            } else {
                                NotificationManager.shared.cancelEveningReminder()
                            }
                        }
                    }

                    Toggle(isOn: $weeklyCheckin) {
                        Label {
                            Text("settings.notifications.weekly")
                        } icon: {
                            Image(systemName: "calendar.badge.clock")
                                .foregroundStyle(AdKanTheme.primary)
                        }
                    }
                    .tint(AdKanTheme.primary)
                    .onChange(of: weeklyCheckin) { _, enabled in
                        if enabled {
                            NotificationManager.shared.scheduleWeeklyCheckIn(friendName: nil)
                        } else {
                            UNUserNotificationCenter.current()
                                .removePendingNotificationRequests(withIdentifiers: ["weekly_checkin"])
                        }
                    }
                }

                Section("settings.premium") {
                    if storeManager.isPremium {
                        Label {
                            Text("settings.premium.active")
                        } icon: {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(AdKanTheme.brandPurple)
                        }
                    } else {
                        Button(action: { showPaywall = true }) {
                            Label {
                                Text("settings.premium.upgrade")
                            } icon: {
                                Image(systemName: "crown.fill")
                                    .foregroundStyle(.yellow)
                            }
                        }
                        .foregroundStyle(.primary)
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

                #if DEBUG
                Section("🛠 Debug") {
                    Button(storeManager.isPremium ? "Disable Premium" : "Enable Premium") {
                        storeManager.isPremium.toggle()
                    }
                    .foregroundStyle(storeManager.isPremium ? .red : .green)

                    Button("Trigger 7-day Milestone Card") {
                        UserDefaults.standard.removeObject(forKey: "shownMilestonesV1")
                        // Force streak to 7 so HomeView shows the share card on next load
                        var dates: [Date] = []
                        for i in 0..<7 {
                            if let d = Calendar.current.date(byAdding: .day, value: -i, to: Date()) {
                                dates.append(Calendar.current.startOfDay(for: d))
                            }
                        }
                        if let data = try? JSONEncoder().encode(dates) {
                            UserDefaults.standard.set(data, forKey: "streakGoalMetDates")
                        }
                    }
                    .foregroundStyle(.orange)

                    Button("Reset Streak") {
                        UserDefaults.standard.removeObject(forKey: "streakGoalMetDates")
                        UserDefaults.standard.removeObject(forKey: "streakLongest")
                        UserDefaults.standard.removeObject(forKey: "shownMilestonesV1")
                    }
                    .foregroundStyle(.red)
                }
                #endif
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
