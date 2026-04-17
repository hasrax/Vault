//
//  NotificationService.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-04-02.
//

import Foundation
import UIKit
import UserNotifications

struct NotificationService {
    private static let defaults = UserDefaults.standard

    static func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                DispatchQueue.main.async {
                    if granted {
                        registerForRemoteNotifications()
                    }
                    completion?(granted)
                }
            }
    }

    static func registerForRemoteNotifications() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    static func sendLocalNotification(title: String, body: String, type: AppNotification.NotiType) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)

        let item = AppNotification(
            title: title,
            message: body,
            type: type,
            time: NotificationStore.relativeTimeString(from: Date())
        )
        NotificationStore.shared.add(item)
    }

    static func sendLocalNotificationIfNeeded(
        key: String,
        title: String,
        body: String,
        type: AppNotification.NotiType,
        cooldown: TimeInterval = 3600
    ) {
        let now = Date().timeIntervalSince1970
        let last = defaults.double(forKey: key)
        if last > 0 && now - last < cooldown { return }
        defaults.set(now, forKey: key)
        sendLocalNotification(title: title, body: body, type: type)
    }
}
