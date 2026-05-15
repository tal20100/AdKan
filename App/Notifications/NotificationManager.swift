import Foundation
import UserNotifications
import UIKit

final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published private(set) var isAuthorized = false

    private let center = UNUserNotificationCenter.current()
    private let dailyCountKey = "notif_daily_count"
    private let dailyCountDateKey = "notif_daily_count_date"
    private let maxPerDay = 3

    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run { isAuthorized = granted }
            return granted
        } catch {
            return false
        }
    }

    func checkStatus() async {
        let settings = await center.notificationSettings()
        await MainActor.run {
            isAuthorized = settings.authorizationStatus == .authorized
        }
    }

    // MARK: - Rate Limiting (3/day hard cap)

    private func canSendToday() -> Bool {
        let today = Calendar.current.startOfDay(for: Date())
        let storedDate = UserDefaults.standard.object(forKey: dailyCountDateKey) as? Date ?? .distantPast
        if Calendar.current.startOfDay(for: storedDate) != today {
            UserDefaults.standard.set(0, forKey: dailyCountKey)
            UserDefaults.standard.set(today, forKey: dailyCountDateKey)
        }
        return UserDefaults.standard.integer(forKey: dailyCountKey) < maxPerDay
    }

    private func recordSent() {
        let today = Calendar.current.startOfDay(for: Date())
        let storedDate = UserDefaults.standard.object(forKey: dailyCountDateKey) as? Date ?? .distantPast
        if Calendar.current.startOfDay(for: storedDate) != today {
            UserDefaults.standard.set(1, forKey: dailyCountKey)
            UserDefaults.standard.set(today, forKey: dailyCountDateKey)
        } else {
            let count = UserDefaults.standard.integer(forKey: dailyCountKey)
            UserDefaults.standard.set(count + 1, forKey: dailyCountKey)
        }
    }

    private func variantIndex(count: Int) -> Int {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return day % count
    }

    private func didSendType(_ type: String, today: Bool = true) -> Bool {
        guard today else { return false }
        let key = "notif_sent_\(type)_\(Calendar.current.startOfDay(for: Date()).timeIntervalSince1970)"
        return UserDefaults.standard.bool(forKey: key)
    }

    private func markSentType(_ type: String) {
        let key = "notif_sent_\(type)_\(Calendar.current.startOfDay(for: Date()).timeIntervalSince1970)"
        UserDefaults.standard.set(true, forKey: key)
    }

    // MARK: - Rank Change Alert (immediate, always-on)

    func sendRankChangeAlert(groupName: String, oldRank: Int, newRank: Int) {
        guard canSendToday() else { return }
        guard UIApplication.shared.applicationState != .active else { return }

        let content = UNMutableNotificationContent()
        content.sound = .default

        let v = variantIndex(count: 2)

        if newRank == 1 {
            content.title = NSLocalizedString("notif.rankChange.first.title", comment: "")
            let key = v == 0 ? "notif.rankChange.first.a" : "notif.rankChange.first.b"
            content.body = String(format: NSLocalizedString(key, comment: ""), groupName)
        } else if newRank < oldRank {
            content.title = NSLocalizedString("notif.rankChange.improved.title", comment: "")
            if v == 0 {
                content.body = String(format: NSLocalizedString("notif.rankChange.improved.a", comment: ""), newRank, groupName)
            } else {
                content.body = String(format: NSLocalizedString("notif.rankChange.improved.b", comment: ""), oldRank, newRank, groupName)
            }
        } else {
            content.title = NSLocalizedString("notif.rankChange.dropped.title", comment: "")
            if v == 0 {
                content.body = String(format: NSLocalizedString("notif.rankChange.dropped.a", comment: ""), oldRank, newRank, groupName)
            } else {
                content.body = String(format: NSLocalizedString("notif.rankChange.dropped.b", comment: ""), newRank, groupName)
            }
            markSentType("rank_drop")
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "rank_change", content: content, trigger: trigger)
        center.removePendingNotificationRequests(withIdentifiers: ["rank_change"])
        center.add(request)
        recordSent()
    }

    // MARK: - Goal Celebration (11 PM, default ON)

    func scheduleGoalCelebration(savedMinutes: Int, streak: Int) {
        guard canSendToday() else { return }

        let content = UNMutableNotificationContent()
        content.sound = .default
        content.title = NSLocalizedString("notif.goalCelebration.title", comment: "")

        let variantCount = streak >= 7 ? 3 : 2
        let v = variantIndex(count: variantCount)

        switch v {
        case 0:
            content.body = String(format: NSLocalizedString("notif.goalCelebration.a", comment: ""), savedMinutes, streak)
        case 1:
            content.body = String(format: NSLocalizedString("notif.goalCelebration.b", comment: ""), savedMinutes, streak)
        default:
            content.body = String(format: NSLocalizedString("notif.goalCelebration.c", comment: ""), streak)
        }

        var dateComponents = DateComponents()
        dateComponents.hour = 23

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: "goal_celebration", content: content, trigger: trigger)
        center.removePendingNotificationRequests(withIdentifiers: ["goal_celebration"])
        center.add(request)
        recordSent()
    }

    func cancelGoalCelebration() {
        center.removePendingNotificationRequests(withIdentifiers: ["goal_celebration"])
    }

    // MARK: - Inactivity Re-engagement (48h, default ON)

    func scheduleInactivityReengagement(groupName: String?, lastRank: Int?, streak: Int) {
        center.removePendingNotificationRequests(withIdentifiers: ["inactivity_reengagement"])

        let content = UNMutableNotificationContent()
        content.sound = .default

        if let group = groupName {
            content.title = String(format: NSLocalizedString("notif.inactivity.title", comment: ""), group)
        } else {
            content.title = NSLocalizedString("notif.inactivity.title.noGroup", comment: "")
        }

        let v = variantIndex(count: 3)
        switch v {
        case 0:
            if let rank = lastRank {
                content.body = String(format: NSLocalizedString("notif.inactivity.a", comment: ""), rank)
            } else {
                content.body = NSLocalizedString("notif.inactivity.c", comment: "")
            }
        case 1:
            if let group = groupName {
                content.body = String(format: NSLocalizedString("notif.inactivity.b", comment: ""), group)
            } else {
                content.body = NSLocalizedString("notif.inactivity.c", comment: "")
            }
        default:
            content.body = NSLocalizedString("notif.inactivity.c", comment: "")
        }

        // 48h from now, but cap at 72h (don't fire beyond that)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 48 * 3600, repeats: false)
        let request = UNNotificationRequest(identifier: "inactivity_reengagement", content: content, trigger: trigger)
        center.add(request)
    }

    func cancelInactivityReengagement() {
        center.removePendingNotificationRequests(withIdentifiers: ["inactivity_reengagement"])
    }

    // MARK: - Weekly Check-In (Sunday 10 AM, enhanced with stats)

    func scheduleWeeklyCheckIn(friendName: String?, streak: Int = 0, weeklyTotal: String? = nil, bestRank: Int? = nil, groupName: String? = nil) {
        let content = UNMutableNotificationContent()
        content.sound = .default
        content.title = NSLocalizedString("notif.weekly.title.v2", comment: "")

        if let total = weeklyTotal, let rank = bestRank, let group = groupName {
            let v = variantIndex(count: 2)
            if v == 0 {
                content.body = String(format: NSLocalizedString("notif.weekly.a", comment: ""), total, rank, group, group)
            } else {
                content.body = String(format: NSLocalizedString("notif.weekly.b", comment: ""), total, streak)
            }
        } else if let name = friendName {
            content.body = String(format: NSLocalizedString("notif.weekly.body.friend", comment: ""), name)
        } else {
            content.body = NSLocalizedString("notif.weekly.fallback", comment: "")
        }

        var dateComponents = DateComponents()
        dateComponents.weekday = 6
        dateComponents.hour = 10

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "weekly_checkin", content: content, trigger: trigger)
        center.removePendingNotificationRequests(withIdentifiers: ["weekly_checkin"])
        center.add(request)
    }

    // MARK: - Streak Milestone (unchanged)

    func sendStreakMilestone(days: Int) {
        let content = UNMutableNotificationContent()
        content.title = String(format: NSLocalizedString("notif.streak.title", comment: ""), days)
        content.body = NSLocalizedString("notif.streak.body", comment: "")
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "streak_\(days)",
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    // MARK: - Evening Reminder (opt-in, enhanced with data)

    func scheduleEveningReminder(hour: Int = 21, todayMinutes: Int = 0, goalMinutes: Int = 120) {
        let content = UNMutableNotificationContent()
        content.sound = .default

        let remaining = goalMinutes - todayMinutes
        let v = variantIndex(count: 2)

        if remaining > 30 {
            content.title = NSLocalizedString("notif.evening.under.title", comment: "")
            let key = v == 0 ? "notif.evening.under.a" : "notif.evening.under.b"
            content.body = String(format: NSLocalizedString(key, comment: ""), todayMinutes, remaining)
        } else if remaining > 0 {
            content.title = NSLocalizedString("notif.evening.close.title", comment: "")
            let key = v == 0 ? "notif.evening.close.a" : "notif.evening.close.b"
            content.body = String(format: NSLocalizedString(key, comment: ""), todayMinutes, remaining)
        } else {
            if didSendType("rank_drop") { return }
            content.title = NSLocalizedString("notif.evening.over.title", comment: "")
            let key = v == 0 ? "notif.evening.over.a" : "notif.evening.over.b"
            content.body = String(format: NSLocalizedString(key, comment: ""), todayMinutes, goalMinutes)
        }

        var dateComponents = DateComponents()
        dateComponents.hour = hour

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "evening_reminder", content: content, trigger: trigger)
        center.removePendingNotificationRequests(withIdentifiers: ["evening_reminder"])
        center.add(request)
    }

    func cancelEveningReminder() {
        center.removePendingNotificationRequests(withIdentifiers: ["evening_reminder"])
    }

    // MARK: - Streak-at-Risk (rescheduled each time screen time updates)

    func rescheduleStreakAtRisk(streak: Int, todayMinutes: Int, goalMinutes: Int) {
        center.removePendingNotificationRequests(withIdentifiers: ["streak_at_risk"])

        guard streak > 0 else { return }

        let content = UNMutableNotificationContent()
        content.sound = .default

        if todayMinutes > goalMinutes {
            content.title = NSLocalizedString("notif.streakAtRisk.title", comment: "")
            content.body = String(format: NSLocalizedString("notif.streakAtRisk.body.broken", comment: ""), streak)
        } else if todayMinutes >= Int(Double(goalMinutes) * 0.75) {
            let remaining = goalMinutes - todayMinutes
            content.title = NSLocalizedString("notif.streakAtRisk.title", comment: "")
            content.body = String(format: NSLocalizedString("notif.streakAtRisk.body.atRisk", comment: ""), streak, remaining)
        } else {
            return
        }

        var dateComponents = DateComponents()
        dateComponents.hour = 20
        dateComponents.minute = 30

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: "streak_at_risk", content: content, trigger: trigger)
        center.add(request)
    }

    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }
}
