//
//  NotificationManager.swift
//  GameFinder
//
//  Created by Claude on 10/5/25.
//

import Foundation
import UIKit
import RxSwift
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()

    private let repository: RealmGameRepository
    private let notificationCenter = UNUserNotificationCenter.current()

    // 알림 상태 변경을 알리는 Subject (gameId, isNotificationEnabled)
    let notificationStatusChanged = PublishSubject<(Int, Bool)>()

    private init() {
        repository = RealmGameRepository()
    }

    // MARK: - Permission
    func requestPermission(completion: @escaping (Bool) -> Void) {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                LogManager.error.error("Notification permission error: \(error.localizedDescription)")
            }
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    func checkPermissionStatus(completion: @escaping (Bool) -> Void) {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus == .authorized)
            }
        }
    }

    // MARK: - Add Notification
    func addNotification(_ game: Game) -> Bool {
        guard repository.saveOrUpdateGame(game) else {
            LogManager.error.error("Failed to save game for notification: \(game.id)")
            return false
        }

        guard repository.updateNotification(gameId: game.id, isEnabled: true) else {
            LogManager.error.error("Failed to update notification status: \(game.id)")
            return false
        }

        // 로컬 알림 스케줄링 (전역 알림이 활성화된 경우만)
        if UserDefaults.isGlobalNotificationEnabled {
            scheduleLocalNotification(for: game)
        }

        // 로깅 및 Analytics
        LogManager.logAddNotification(gameId: game.id, gameName: game.name)

        notificationStatusChanged.onNext((game.id, true))
        return true
    }

    // MARK: - Remove Notification
    func removeNotification(gameId: Int) -> Bool {
        guard repository.updateNotification(gameId: gameId, isEnabled: false) else {
            LogManager.error.error("Failed to remove notification: \(gameId)")
            return false
        }

        // 로컬 알림 취소
        cancelLocalNotification(for: gameId)

        _ = repository.deleteGameIfUnused(gameId: gameId)

        // 로깅 및 Analytics
        LogManager.logRemoveNotification(gameId: gameId)

        notificationStatusChanged.onNext((gameId, false))
        return true
    }

    // MARK: - Check if Notification Enabled
    func isNotificationEnabled(gameId: Int) -> Bool {
        guard let realmGame = repository.findGameById(gameId) else {
            return false
        }
        return realmGame.isNotificationEnabled
    }

    // MARK: - Get All Notifications
    func getAllNotifications() -> [Game] {
        return repository.findNotifications()
    }

    // MARK: - Observe Notifications (Rx)
    func observeNotifications() -> Observable<[Game]> {
        return repository.observeNotifications()
    }

    // MARK: - Toggle Notification
    func toggleNotification(_ game: Game) -> Bool {
        if isNotificationEnabled(gameId: game.id) {
            return removeNotification(gameId: game.id)
        } else {
            return addNotification(game)
        }
    }

    // MARK: - Global Notification Toggle
    func toggleGlobalNotification(enabled: Bool) {
        UserDefaults.isGlobalNotificationEnabled = enabled

        if enabled {
            // 전역 알림 활성화 시 모든 알림 활성화된 게임에 대해 스케줄링
            rescheduleAllNotifications()
        } else {
            // 전역 알림 비활성화 시 모든 예약된 알림 취소
            cancelAllLocalNotifications()
        }
    }

    // MARK: - Local Notification Scheduling
    private func scheduleLocalNotification(for game: Game) {
        guard let releaseDateString = game.released,
              let releaseDate = parseReleaseDate(releaseDateString) else {
            LogManager.error.error("Invalid release date for game: \(game.id)")
            return
        }

        // 출시일 하루 전 오후 6시 계산
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: releaseDate)
        dateComponents.hour = 18
        dateComponents.minute = 0

        guard let notificationDate = Calendar.current.date(from: dateComponents),
              let oneDayBefore = Calendar.current.date(byAdding: .day, value: -1, to: notificationDate) else {
            return
        }

        // 이미 지난 날짜면 스케줄링하지 않음
        if oneDayBefore < Date() {
            LogManager.userAction.info("Notification date has passed for game: \(game.id)")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = L10n.Notification.title
        content.body = String(format: L10n.Notification.body, game.name)
        content.sound = .default
        content.userInfo = ["gameId": game.id]
        // 일반 게임 알림은 badge를 설정하지 않음 (delivered notifications만 badge에 영향)

        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: oneDayBefore)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        let identifier = "game_\(game.id)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        notificationCenter.add(request) { error in
            if let error = error {
                LogManager.error.error("Failed to schedule notification for game \(game.id): \(error.localizedDescription)")
            } else {
                LogManager.userAction.info("🔔 Scheduled notification for game \(game.id) at \(oneDayBefore)")
            }
        }
    }

    private func cancelLocalNotification(for gameId: Int) {
        let identifier = "game_\(gameId)"
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        LogManager.userAction.info("🔕 Cancelled notification for game: \(gameId)")
    }

    private func cancelAllLocalNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        LogManager.userAction.info("🔕 Cancelled all notifications")
    }

    private func rescheduleAllNotifications() {
        let games = getAllNotifications()
        for game in games {
            scheduleLocalNotification(for: game)
        }
        LogManager.userAction.info("🔔 Rescheduled \(games.count) notifications")
    }

    private func parseReleaseDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }

    // MARK: - Test Notifications (for debugging)
    #if DEBUG
    /// 테스트용 로컬 노티피케이션 스케줄링 (1.5초 후 발송)
    /// - Parameters:
    ///   - title: 알림 제목
    ///   - body: 알림 본문
    ///   - delay: 지연 시간(초), 기본값 1.5초
    ///   - badgeNumber: 설정할 뱃지 번호 (nil이면 delivered count + 1 사용)
    func scheduleTestNotification(title: String = "테스트 알림", body: String = "이것은 테스트 알림입니다", delay: TimeInterval = 1.5, badgeNumber: Int? = nil) {
        // 현재 전달된 알림 개수 확인
        UNUserNotificationCenter.current().getDeliveredNotifications { [weak self] deliveredNotifications in
            guard let self = self else { return }

            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default

            // badge는 현재 delivered 개수 + 1 (또는 지정된 번호)
            let badgeValue = badgeNumber ?? (deliveredNotifications.count + 1)
            content.badge = NSNumber(value: badgeValue)

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
            let identifier = "test_\(UUID().uuidString)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            self.notificationCenter.add(request) { error in
                if let error = error {
                    LogManager.error.error("Failed to schedule test notification: \(error.localizedDescription)")
                } else {
                    LogManager.userAction.info("🔔 Test notification scheduled for \(delay) seconds later with badge \(badgeValue)")
                    print("✅ 테스트 알림이 \(delay)초 후에 발송됩니다 (뱃지: \(badgeValue)). 앱을 백그라운드로 전환하세요.")
                }
            }
        }
    }

    /// 여러 개의 테스트 알림을 연속으로 스케줄링
    /// - Parameter count: 생성할 알림 개수
    func scheduleMultipleTestNotifications(count: Int) {
        // 현재 전달된 알림 개수 확인
        UNUserNotificationCenter.current().getDeliveredNotifications { [weak self] deliveredNotifications in
            guard let self = self else { return }

            let baseCount = deliveredNotifications.count

            for i in 0..<count {
                let delay = TimeInterval(1.5 + (Double(i) * 1.5)) // 1.5초, 3초, 4.5초, 6초...
                let badgeNumber = baseCount + i + 1 // 순차적으로 증가하는 뱃지 번호

                self.scheduleTestNotification(
                    title: "테스트 알림 #\(i + 1)",
                    body: "\(i + 1)번째 테스트 알림입니다",
                    delay: delay,
                    badgeNumber: badgeNumber
                )
            }

            print("✅ \(count)개의 테스트 알림이 스케줄되었습니다.")
            print("   전달된 알림: \(baseCount)개")
            print("   뱃지 번호: \(baseCount + 1) ~ \(baseCount + count)")
            print("   앱을 백그라운드로 전환하세요.")
        }
    }

    /// 모든 대기 중인 알림 정보 출력
    func printPendingNotifications() {
        notificationCenter.getPendingNotificationRequests { requests in
            print("\n📋 대기 중인 알림: \(requests.count)개")
            for (index, request) in requests.enumerated() {
                print("  [\(index + 1)] ID: \(request.identifier)")
                print("      제목: \(request.content.title)")
                print("      본문: \(request.content.body)")
                if let trigger = request.trigger as? UNCalendarNotificationTrigger,
                   let nextDate = trigger.nextTriggerDate() {
                    print("      발송 예정: \(nextDate)")
                } else if let trigger = request.trigger as? UNTimeIntervalNotificationTrigger {
                    print("      발송까지 남은 시간: \(trigger.timeInterval)초")
                }
                print("      뱃지: \(request.content.badge ?? 0)")
            }
            print("")
        }
    }

    /// 모든 전달된 알림 정보 출력
    func printDeliveredNotifications() {
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            print("\n📬 전달된 알림: \(notifications.count)개")
            for (index, notification) in notifications.enumerated() {
                print("  [\(index + 1)] ID: \(notification.request.identifier)")
                print("      제목: \(notification.request.content.title)")
                print("      본문: \(notification.request.content.body)")
                print("      뱃지: \(notification.request.content.badge ?? 0)")
            }
            print("현재 앱 뱃지: \(UIApplication.shared.applicationIconBadgeNumber)")
            print("")
        }
    }
    #endif
}
