import UIKit
import UserNotifications
import FirebaseMessaging

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    private var handledNotificationIds = Set<String>()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        PushTokenStore.shared.updateApnsToken(tokenString)
    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken, !token.isEmpty else { return }
        PushTokenStore.shared.updateFcmToken(token)
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        storeNotificationIfNeeded(notification)
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        storeNotificationIfNeeded(response.notification)
        completionHandler()
    }

    private func storeNotificationIfNeeded(_ notification: UNNotification) {
        let id = notification.request.identifier
        if handledNotificationIds.contains(id) {
            return
        }
        handledNotificationIds.insert(id)

        let content = notification.request.content
        let title = content.title.isEmpty ? "Notification" : content.title
        let body = content.body
        let type = inferType(from: content.userInfo)
        let item = AppNotification(
            title: title,
            message: body,
            type: type,
            time: NotificationStore.relativeTimeString(from: Date())
        )
        NotificationStore.shared.add(item)
    }

    private func inferType(from userInfo: [AnyHashable: Any]) -> AppNotification.NotiType {
        if let raw = userInfo["type"] as? String,
           let parsed = AppNotification.NotiType(rawValue: raw) {
            return parsed
        }
        return .planner
    }
}
