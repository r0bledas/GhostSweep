import Foundation
import UserNotifications

public final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    public static let shared = NotificationManager()

    public var isAvailable: Bool {
        guard NSClassFromString("XCTest") == nil else { return false }
        guard let id = Bundle.main.bundleIdentifier, !id.isEmpty, !id.contains("xctest") else { return false }
        return true
    }

    private override init() {
        super.init()
        guard NSClassFromString("XCTest") == nil else { return }
        guard let id = Bundle.main.bundleIdentifier, !id.isEmpty, !id.contains("xctest") else { return }
        UNUserNotificationCenter.current().delegate = self
    }

    public func requestAuthorization() {
        guard isAvailable else { return }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("[NotificationManager] Authorization error: \(error.localizedDescription)")
            }
        }
    }

    public func sendNotification(
        title: String,
        subtitle: String? = nil,
        body: String,
        identifier: String = UUID().uuidString
    ) {
        guard isAvailable else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        if let subtitle = subtitle {
            content.subtitle = subtitle
        }
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("[NotificationManager] Delivery error: \(error.localizedDescription)")
            }
        }
    }

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
