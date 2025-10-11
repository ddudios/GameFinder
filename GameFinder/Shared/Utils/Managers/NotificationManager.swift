//
//  NotificationManager.swift
//  GameFinder
//
//  Created by Claude on 10/5/25.
//

import Foundation
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
        content.badge = 1
        content.userInfo = ["gameId": game.id]

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
}
