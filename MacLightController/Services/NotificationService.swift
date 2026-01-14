// Services/NotificationService.swift
// MacLightController
//
// Service for sending system notifications

import Foundation
import UserNotifications
import os.log

/// Service for managing system notifications
@MainActor
final class NotificationService: ObservableObject {
    static let shared = NotificationService()

    @Published private(set) var isAuthorized: Bool = false

    private let logger = Logger(subsystem: "com.maclightcontroller", category: "NotificationService")
    private let notificationCenter = UNUserNotificationCenter.current()

    private init() {}

    // MARK: - Authorization

    /// Request notification authorization
    func requestAuthorization() async {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
            logger.info("Notification authorization: \(granted)")
        } catch {
            logger.error("Failed to request notification authorization: \(error.localizedDescription)")
            isAuthorized = false
        }
    }

    /// Check current authorization status
    func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    // MARK: - Sending Notifications

    /// Send a success notification
    func sendSuccess(title: String, message: String) async {
        await send(
            title: title,
            body: message,
            categoryIdentifier: "SUCCESS"
        )
    }

    /// Send an error notification
    func sendError(title: String, message: String) async {
        await send(
            title: title,
            body: message,
            categoryIdentifier: "ERROR"
        )
    }

    /// Send an info notification
    func sendInfo(title: String, message: String) async {
        await send(
            title: title,
            body: message,
            categoryIdentifier: "INFO"
        )
    }

    /// Send a custom notification
    func send(
        title: String,
        body: String,
        subtitle: String? = nil,
        categoryIdentifier: String = "DEFAULT",
        userInfo: [String: Any] = [:],
        sound: UNNotificationSound? = .default
    ) async {
        guard isAuthorized else {
            logger.warning("Notifications not authorized, skipping notification")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        if let subtitle = subtitle {
            content.subtitle = subtitle
        }
        content.categoryIdentifier = categoryIdentifier
        content.userInfo = userInfo
        content.sound = sound

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Immediate delivery
        )

        do {
            try await notificationCenter.add(request)
            logger.info("Notification sent: \(title)")
        } catch {
            logger.error("Failed to send notification: \(error.localizedDescription)")
        }
    }

    // MARK: - Scheduled Notifications

    /// Schedule a notification for a specific time
    func schedule(
        title: String,
        body: String,
        at date: Date,
        identifier: String? = nil
    ) async {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: identifier ?? UUID().uuidString,
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
            logger.info("Notification scheduled: \(title) at \(date)")
        } catch {
            logger.error("Failed to schedule notification: \(error.localizedDescription)")
        }
    }

    /// Cancel a scheduled notification
    func cancel(identifier: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        logger.info("Notification cancelled: \(identifier)")
    }

    /// Cancel all pending notifications
    func cancelAll() {
        notificationCenter.removeAllPendingNotificationRequests()
        logger.info("All notifications cancelled")
    }

    // MARK: - Notification Categories

    /// Setup notification categories with actions
    func setupCategories() {
        let stopAction = UNNotificationAction(
            identifier: "STOP_AUTOMATION",
            title: "Ferma Automazione",
            options: .destructive
        )

        let viewAction = UNNotificationAction(
            identifier: "VIEW_DETAILS",
            title: "Visualizza Dettagli",
            options: .foreground
        )

        let successCategory = UNNotificationCategory(
            identifier: "SUCCESS",
            actions: [viewAction],
            intentIdentifiers: [],
            options: []
        )

        let errorCategory = UNNotificationCategory(
            identifier: "ERROR",
            actions: [viewAction, stopAction],
            intentIdentifiers: [],
            options: []
        )

        let infoCategory = UNNotificationCategory(
            identifier: "INFO",
            actions: [viewAction],
            intentIdentifiers: [],
            options: []
        )

        notificationCenter.setNotificationCategories([successCategory, errorCategory, infoCategory])
        logger.info("Notification categories configured")
    }
}
