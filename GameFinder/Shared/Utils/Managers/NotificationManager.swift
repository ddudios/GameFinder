//
//  NotificationManager.swift
//  GameFinder
//
//  Created by Claude on 10/5/25.
//

import Foundation
import RealmSwift
import RxSwift

final class NotificationManager {
    static let shared = NotificationManager()

    private let realm: Realm

    // 알림 상태 변경을 알리는 Subject (gameId, isNotificationEnabled)
    let notificationStatusChanged = PublishSubject<(Int, Bool)>()

    private init() {
        do {
            realm = try Realm()
        } catch {
            fatalError("Realm initialization failed: \(error)")
        }
    }

    // MARK: - Add Notification
    func addNotification(_ game: Game) -> Bool {
        do {
            try realm.write {
                if let existingGame = realm.object(ofType: RealmGame.self, forPrimaryKey: game.id) {
                    // 이미 존재하는 게임 - isNotificationEnabled만 업데이트
                    existingGame.isNotificationEnabled = true
                    existingGame.notificationAddedAt = Date()
                } else {
                    // 새 게임 추가
                    let realmGame = RealmGame(from: game)
                    realmGame.isNotificationEnabled = true
                    realmGame.notificationAddedAt = Date()
                    realm.add(realmGame, update: .modified)
                }
            }
            notificationStatusChanged.onNext((game.id, true))
            return true
        } catch {
            print("Failed to add notification: \(error)")
            return false
        }
    }

    // MARK: - Remove Notification
    func removeNotification(gameId: Int) -> Bool {
        do {
            guard let realmGame = realm.object(ofType: RealmGame.self, forPrimaryKey: gameId) else {
                return false
            }
            try realm.write {
                realmGame.isNotificationEnabled = false
                realmGame.notificationAddedAt = nil

                // isFavorite와 isNotificationEnabled 둘 다 false면 삭제
                if !realmGame.isFavorite && !realmGame.isNotificationEnabled {
                    realm.delete(realmGame)
                }
            }
            notificationStatusChanged.onNext((gameId, false))
            return true
        } catch {
            print("Failed to remove notification: \(error)")
            return false
        }
    }

    // MARK: - Check if Notification Enabled
    func isNotificationEnabled(gameId: Int) -> Bool {
        guard let realmGame = realm.object(ofType: RealmGame.self, forPrimaryKey: gameId) else {
            return false
        }
        return realmGame.isNotificationEnabled
    }

    // MARK: - Get All Notifications
    func getAllNotifications() -> [Game] {
        let notifications = realm.objects(RealmGame.self)
            .where { $0.isNotificationEnabled == true }
            .sorted(byKeyPath: "notificationAddedAt", ascending: false)
        return Array(notifications.map { $0.toDomain() })
    }

    // MARK: - Observe Notifications (Rx)
    func observeNotifications() -> Observable<[Game]> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onCompleted()
                return Disposables.create()
            }

            let results = self.realm.objects(RealmGame.self)
                .where { $0.isNotificationEnabled == true }
                .sorted(byKeyPath: "notificationAddedAt", ascending: false)

            let token = results.observe { changes in
                switch changes {
                case .initial(let collection):
                    observer.onNext(Array(collection.map { $0.toDomain() }))
                case .update(let collection, _, _, _):
                    observer.onNext(Array(collection.map { $0.toDomain() }))
                case .error(let error):
                    observer.onError(error)
                }
            }

            return Disposables.create {
                token.invalidate()
            }
        }
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
