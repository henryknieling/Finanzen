import Foundation
import UserNotifications

enum BudgetReminderScheduler {
    static let enabledKey = "finanzen.monthlyBudgetReminderEnabled"
    private static let notificationID = "finanzen.monthlyBudgetReminder"

    static func setEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: enabledKey)
        let center = UNUserNotificationCenter.current()

        guard enabled else {
            center.removePendingNotificationRequests(withIdentifiers: [notificationID])
            return
        }

        Task {
            let settings = await center.notificationSettings()
            if settings.authorizationStatus == .notDetermined {
                guard (try? await center.requestAuthorization(options: [.alert, .sound])) == true else { return }
            } else if settings.authorizationStatus != .authorized && settings.authorizationStatus != .provisional {
                return
            }

            await scheduleNextReminder(using: center)
        }
    }

    static func refreshIfEnabled() {
        guard UserDefaults.standard.bool(forKey: enabledKey) else { return }
        let center = UNUserNotificationCenter.current()
        Task {
            let settings = await center.notificationSettings()
            guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else { return }
            await scheduleNextReminder(using: center)
        }
    }

    private static func scheduleNextReminder(using center: UNUserNotificationCenter) async {
        let calendar = Calendar.current
        var match = DateComponents()
        match.day = 1
        match.hour = 9
        match.minute = 0
        guard let date = calendar.nextDate(after: .now, matching: match, matchingPolicy: .nextTime) else { return }

        let content = UNMutableNotificationContent()
        content.title = "Monatsbudget festlegen"
        content.body = "Lege dein Budget für den neuen Monat in Finanzen fest."
        content.sound = .default

        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: notificationID, content: content, trigger: trigger)

        center.removePendingNotificationRequests(withIdentifiers: [notificationID])
        try? await center.add(request)
    }
}
