//
//  NotificationService.swift
//  NotificationServiceExtension
//
//  Created by Claude on 10/16/25.
//

import UserNotifications

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        if let bestAttemptContent = bestAttemptContent {
            // 현재 전달된 알림 개수를 가져와서 뱃지 설정
            UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
                // 현재 알림 + 1 (새로 도착한 알림)
                let badgeCount = notifications.count + 1
                bestAttemptContent.badge = NSNumber(value: badgeCount)

                contentHandler(bestAttemptContent)
            }
        }
    }

    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
}
