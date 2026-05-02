import Foundation
import UserNotifications

final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published private(set) var isAuthorized = false

    private let center = UNUserNotificationCenter.current()

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

    // MARK: - Weekly Check-In (1x per week, Sunday 10 AM)

    func scheduleWeeklyCheckIn(friendName: String?) {
        let content = UNMutableNotificationContent()
        content.sound = .default

        if let name = friendName {
            content.title = NSLocalizedString("notif.weekly.title", comment: "")
            content.body = String(format: NSLocalizedString("notif.weekly.body.friend", comment: ""), name)
        } else {
            content.title = NSLocalizedString("notif.weekly.title", comment: "")
            content.body = NSLocalizedString("notif.weekly.body.solo", comment: "")
        }

        var dateComponents = DateComponents()
        dateComponents.weekday = 1 // Sunday
        dateComponents.hour = 10

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "weekly_checkin", content: content, trigger: trigger)

        center.removePendingNotificationRequests(withIdentifiers: ["weekly_checkin"])
        center.add(request)
    }

    // MARK: - Streak Milestone

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

    // MARK: - Evening Reminder (opt-in, 1x per day)

    func scheduleEveningReminder(hour: Int = 21) {
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("notif.evening.title", comment: "")
        content.body = NSLocalizedString("notif.evening.body", comment: "")
        content.sound = .default

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

    /// Call this whenever today's screen-time reading changes.
    /// Schedules (or cancels) an 8:30 PM notification based on whether the streak is at risk.
    func rescheduleStreakAtRisk(streak: Int, todayMinutes: Int, goalMinutes: Int) {
        center.removePendingNotificationRequests(withIdentifiers: ["streak_at_risk"])

        // Only warn when there's a streak worth protecting
        guard streak > 0 else { return }

        let content = UNMutableNotificationContent()
        content.sound = .default

        if todayMinutes > goalMinutes {
            // Already over — streak is broken
            content.title = NSLocalizedString("notif.streakAtRisk.title", comment: "")
            content.body = String(format: NSLocalizedString("notif.streakAtRisk.body.broken", comment: ""), streak)
        } else if todayMinutes >= Int(Double(goalMinutes) * 0.75) {
            // At 75%+ of budget — warn while there's still time to course-correct
            let remaining = goalMinutes - todayMinutes
            content.title = NSLocalizedString("notif.streakAtRisk.title", comment: "")
            content.body = String(format: NSLocalizedString("notif.streakAtRisk.body.atRisk", comment: ""), streak, remaining)
        } else {
            // User is well under budget — no need to interrupt
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
