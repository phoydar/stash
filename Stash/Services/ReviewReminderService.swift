import Foundation
import UserNotifications

enum ReviewReminderServiceError: Error, LocalizedError {
    case notificationsNotAllowed
    case reminderDateInPast

    var errorDescription: String? {
        switch self {
        case .notificationsNotAllowed:
            return "Review reminders need notification permission. You can enable notifications for Stash in Settings."
        case .reminderDateInPast:
            return "Choose a future date and time for the review reminder."
        }
    }
}

final class ReviewReminderService {
    static let shared = ReviewReminderService()

    private let notificationCenter: UNUserNotificationCenter

    init(notificationCenter: UNUserNotificationCenter = .current()) {
        self.notificationCenter = notificationCenter
    }

    func updateReminder(for item: InventoryItem, at reminderDate: Date?) async throws {
        if let existingNotificationID = item.reviewNotificationID {
            notificationCenter.removePendingNotificationRequests(withIdentifiers: [existingNotificationID])
        }

        guard let reminderDate else {
            item.reviewReminderAt = nil
            item.reviewNotificationID = nil
            return
        }

        guard reminderDate > Date() else {
            throw ReviewReminderServiceError.reminderDateInPast
        }

        let settings = await notificationCenter.notificationSettings()
        if settings.authorizationStatus == .notDetermined {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            guard granted else {
                throw ReviewReminderServiceError.notificationsNotAllowed
            }
        } else if settings.authorizationStatus != .authorized && settings.authorizationStatus != .provisional {
            throw ReviewReminderServiceError.notificationsNotAllowed
        }

        let notificationID = item.reviewNotificationID ?? "stash-review-\(item.id.uuidString)"
        let content = UNMutableNotificationContent()
        content.title = "Review \(item.name)"
        content.body = "Check whether this item still belongs in your Stash."
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminderDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: notificationID,
            content: content,
            trigger: trigger
        )

        try await notificationCenter.add(request)
        item.reviewReminderAt = reminderDate
        item.reviewNotificationID = notificationID
    }

    func cancelReminder(for item: InventoryItem) {
        guard let notificationID = item.reviewNotificationID else {
            return
        }

        notificationCenter.removePendingNotificationRequests(withIdentifiers: [notificationID])
        item.reviewReminderAt = nil
        item.reviewNotificationID = nil
    }

    func cancelReminders(for container: StorageContainer) {
        for item in container.items {
            cancelReminder(for: item)
        }
    }
}
