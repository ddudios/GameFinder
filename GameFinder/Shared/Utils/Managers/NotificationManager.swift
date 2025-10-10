//
//  NotificationManager.swift
//  GameFinder
//
//  Created by Claude on 10/5/25.
//

import Foundation
import RxSwift

final class NotificationManager {
    static let shared = NotificationManager()

    private let repository: RealmGameRepository

    // 알림 상태 변경을 알리는 Subject (gameId, isNotificationEnabled)
    let notificationStatusChanged = PublishSubject<(Int, Bool)>()

    private init() {
        repository = RealmGameRepository()
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
}
