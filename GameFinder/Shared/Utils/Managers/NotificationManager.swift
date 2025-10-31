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
    private func scheduleLocalNotification(for game: Game, badgeNumber: Int? = nil) {
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

        // 뱃지 번호가 지정된 경우 바로 스케줄링, 아니면 delivered count 기반으로 계산
        if let badge = badgeNumber {
            scheduleNotificationRequest(for: game, at: oneDayBefore, badgeValue: badge)
        } else {
            notificationCenter.getDeliveredNotifications { [weak self] deliveredNotifications in
                guard let self = self else { return }
                let badgeValue = deliveredNotifications.count + 1
                self.scheduleNotificationRequest(for: game, at: oneDayBefore, badgeValue: badgeValue)
            }
        }
    }

    private func scheduleNotificationRequest(for game: Game, at notificationDate: Date, badgeValue: Int) {
        let content = UNMutableNotificationContent()
        content.title = L10n.Notification.title
        content.body = String(format: L10n.Notification.body, game.name)
        content.sound = .default
        content.userInfo = ["gameId": game.id]
        content.badge = NSNumber(value: badgeValue)

        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        let identifier = "game_\(game.id)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        notificationCenter.add(request) { error in
            if let error = error {
                LogManager.error.error("Failed to schedule notification for game \(game.id): \(error.localizedDescription)")
            } else {
                LogManager.userAction.info("🔔 Scheduled notification for game \(game.id) at \(notificationDate) with badge \(badgeValue)")
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

        // 출시일 순서대로 정렬 (빠른 순)
        let sortedGames = games.sorted { game1, game2 in
            guard let date1String = game1.released,
                  let date2String = game2.released,
                  let date1 = parseReleaseDate(date1String),
                  let date2 = parseReleaseDate(date2String) else {
                return false
            }
            return date1 < date2
        }

        // 현재 전달된 알림 개수를 기준으로 순차적으로 badge 할당
        notificationCenter.getDeliveredNotifications { [weak self] deliveredNotifications in
            guard let self = self else { return }

            let baseCount = deliveredNotifications.count

            for (index, game) in sortedGames.enumerated() {
                let badgeNumber = baseCount + index + 1
                self.scheduleLocalNotification(for: game, badgeNumber: badgeNumber)
            }

            LogManager.userAction.info("🔔 Rescheduled \(sortedGames.count) notifications (badge: \(baseCount + 1) ~ \(baseCount + sortedGames.count))")
        }
    }

    private func parseReleaseDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }

    // MARK: - Update Badge for Pending Notifications
    /// 대기 중인 알림들의 뱃지를 현재 상태에 맞게 재조정
    /// - 앱 포그라운드 진입 시 delivered 알림이 제거되면 pending 알림의 badge를 1부터 다시 할당
    func updatePendingNotificationBadges() {
        // 현재 대기 중인 알림들 가져오기
        notificationCenter.getPendingNotificationRequests { [weak self] requests in
            guard let self = self, !requests.isEmpty else { return }

            // pending 알림에서 gameId 추출
            let gameIds = requests.compactMap { request -> Int? in
                guard let gameId = request.content.userInfo["gameId"] as? Int else { return nil }
                return gameId
            }

            // 해당 게임들 조회 및 출시일 순서대로 정렬
            let games = gameIds.compactMap { self.repository.findGameById($0) }
                .map { $0.toDomain() }
                .sorted { game1, game2 in
                    guard let date1String = game1.released,
                          let date2String = game2.released,
                          let date1 = self.parseReleaseDate(date1String),
                          let date2 = self.parseReleaseDate(date2String) else {
                        return false
                    }
                    return date1 < date2
                }

            guard !games.isEmpty else { return }

            // 기존 pending 알림들 모두 제거
            let identifiers = requests.map { $0.identifier }
            self.notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)

            // 새로운 badge 값(1부터 시작)으로 재스케줄링
            for (index, game) in games.enumerated() {
                let badgeNumber = index + 1
                self.scheduleLocalNotification(for: game, badgeNumber: badgeNumber)
            }

            LogManager.userAction.info("🔄 Updated badge for \(games.count) pending notifications (badge: 1 ~ \(games.count))")
        }
    }

    // MARK: - Debug Utilities
    #if DEBUG
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
