//
//  RealmGameRepository.swift
//  GameFinder
//
//  Created by Claude on 10/6/25.
//

import Foundation
import RealmSwift
import RxSwift

final class RealmGameRepository: GameRepository {
    typealias Item = RealmGame

    // 항상 현재 스레드의 Realm 인스턴스를 반환하는 computed property
    private var realm: Realm {
        do {
            return try Realm()
        } catch {
            fatalError("Realm initialization failed: \(error)")
        }
    }

    init() {
        // Realm 설정만 확인 (인스턴스는 사용 시점에 생성)
        do {
            _ = try Realm()
        } catch {
            fatalError("Realm initialization failed: \(error)")
        }
    }

    // MARK: - Create & Update
    func saveOrUpdateGame(_ game: Game) -> Bool {
        do {
            try realm.write {
                let realmGame = getOrCreateRealmGame(game)
                updateGameProperties(realmGame, with: game)
                updateRelations(for: realmGame, with: game)
            }
            LogManager.database.debug("💾 Saved/Updated game: \(game.name) (id: \(game.id))")
            return true
        } catch {
            LogManager.database.error("❌ Failed to save or update game: \(game.id) - \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Read
    func findGameById(_ gameId: Int) -> RealmGame? {
        return realm.objects(RealmGame.self).where { $0.gameId == gameId }.first
    }

    func findFavorites() -> [Game] {
        let favorites = realm.objects(RealmGame.self)
            .where { $0.isFavorite == true }
            .sorted(byKeyPath: "favoriteAddedAt", ascending: false)
        return Array(favorites.map { $0.toDomain() })
    }

    func findNotifications() -> [Game] {
        let notifications = realm.objects(RealmGame.self)
            .where { $0.isNotificationEnabled == true }
            .sorted(byKeyPath: "notificationAddedAt", ascending: false)
        return Array(notifications.map { $0.toDomain() })
    }

    func findReadings() -> [Game] {
        let readings = realm.objects(RealmGame.self)
            .where { $0.isReading == true }
            .sorted(byKeyPath: "readingUpdatedAt", ascending: false)
        return Array(readings.map { $0.toDomain() })
    }

    // MARK: - Observe
    func observeFavorites() -> Observable<[Game]> {
        return Observable.create { observer in
            // 현재 스레드에서 새로운 Realm 인스턴스 생성
            guard let realm = try? Realm() else {
                observer.onError(NSError(domain: "RealmError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create Realm instance"]))
                return Disposables.create()
            }

            let results = realm.objects(RealmGame.self)
                .where { $0.isFavorite == true }
                .sorted(byKeyPath: "favoriteAddedAt", ascending: false)

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

    func observeNotifications() -> Observable<[Game]> {
        return Observable.create { observer in
            // 현재 스레드에서 새로운 Realm 인스턴스 생성
            guard let realm = try? Realm() else {
                observer.onError(NSError(domain: "RealmError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create Realm instance"]))
                return Disposables.create()
            }

            let results = realm.objects(RealmGame.self)
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

    func observeReadings() -> Observable<[Game]> {
        return Observable.create { observer in
            // 현재 스레드에서 새로운 Realm 인스턴스 생성
            guard let realm = try? Realm() else {
                observer.onError(NSError(domain: "RealmError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create Realm instance"]))
                return Disposables.create()
            }

            let results = realm.objects(RealmGame.self)
                .where { $0.isReading == true }
                .sorted(byKeyPath: "readingUpdatedAt", ascending: false)

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

    // MARK: - Update Flags
    func updateFavorite(gameId: Int, isFavorite: Bool) -> Bool {
        guard let realmGame = findGameById(gameId) else {
            LogManager.database.warning("⚠️ Game not found for favorite update: \(gameId)")
            return false
        }

        do {
            try realm.write {
                realmGame.isFavorite = isFavorite
                realmGame.favoriteAddedAt = isFavorite ? Date() : nil
            }
            LogManager.database.debug("💾 Updated favorite: \(gameId) - \(isFavorite)")
            return true
        } catch {
            LogManager.database.error("❌ Failed to update favorite: \(gameId) - \(error.localizedDescription)")
            return false
        }
    }

    func updateNotification(gameId: Int, isEnabled: Bool) -> Bool {
        guard let realmGame = findGameById(gameId) else {
            LogManager.database.warning("⚠️ Game not found for notification update: \(gameId)")
            return false
        }

        do {
            try realm.write {
                realmGame.isNotificationEnabled = isEnabled
                realmGame.notificationAddedAt = isEnabled ? Date() : nil
            }
            LogManager.database.debug("💾 Updated notification: \(gameId) - \(isEnabled)")
            return true
        } catch {
            LogManager.database.error("❌ Failed to update notification: \(gameId) - \(error.localizedDescription)")
            return false
        }
    }

    func updateReading(gameId: Int, isReading: Bool) -> Bool {
        guard let realmGame = findGameById(gameId) else {
            LogManager.database.warning("⚠️ Game not found for reading update: \(gameId)")
            return false
        }

        do {
            try realm.write {
                realmGame.isReading = isReading
                if isReading {
                    // 추가할 때: readingAddedAt이 없으면 설정, readingUpdatedAt은 항상 업데이트
                    if realmGame.readingAddedAt == nil {
                        realmGame.readingAddedAt = Date()
                    }
                    realmGame.readingUpdatedAt = Date()
                } else {
                    // 삭제할 때: 둘 다 nil
                    realmGame.readingAddedAt = nil
                    realmGame.readingUpdatedAt = nil
                }
            }
            LogManager.database.debug("💾 Updated reading: \(gameId) - \(isReading)")
            return true
        } catch {
            LogManager.database.error("❌ Failed to update reading: \(gameId) - \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Delete
    func deleteGameIfUnused(gameId: Int) -> Bool {
        guard let realmGame = findGameById(gameId) else {
            return false
        }

        do {
            try realm.write {
                // isFavorite, isNotificationEnabled, isReading 모두 false면 삭제
                if !realmGame.isFavorite && !realmGame.isNotificationEnabled && !realmGame.isReading {
                    LogManager.database.debug("🗑️ Deleted unused game: \(gameId)")
                    realm.delete(realmGame)
                }
            }
            return true
        } catch {
            LogManager.database.error("❌ Failed to delete game: \(gameId) - \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Count
    func countGames() -> Int {
        return realm.objects(RealmGame.self).count
    }

    // MARK: - Private Helpers
    private func getOrCreateRealmGame(_ game: Game) -> RealmGame {
        if let existingGame = findGameById(game.id) {
            return existingGame
        } else {
            let realmGame = RealmGame()
            realmGame.gameId = game.id
            realm.add(realmGame, update: .modified)
            return realmGame
        }
    }

    private func updateGameProperties(_ realmGame: RealmGame, with game: Game) {
        realmGame.gameId = game.id
        realmGame.name = game.name
        realmGame.released = game.released
        realmGame.backgroundImage = game.backgroundImage
        realmGame.rating = game.rating
        realmGame.ratingsCount = game.ratingsCount
        realmGame.metacritic = game.metacritic
    }

    private func updateRelations(for realmGame: RealmGame, with game: Game) {
        // Platforms 저장 (마스터 테이블, 중복 방지)
        for platform in game.platforms {
            let realmPlatform = realm.objects(RealmPlatform.self)
                .where({ $0.platformId == platform.id }).first
                ?? RealmPlatform(from: platform)
            realm.add(realmPlatform, update: .modified)

            // 게임에 플랫폼 연결 (중복 체크)
            if !realmGame.platforms.contains(where: { $0.platformId == platform.id }) {
                realmGame.platforms.append(realmPlatform)
            }
        }

        // Genres 저장 (마스터 테이블, 중복 방지)
        for genre in game.genres {
            let realmGenre = realm.objects(RealmGenre.self)
                .where({ $0.genreId == genre.id }).first
                ?? RealmGenre(from: genre)
            realm.add(realmGenre, update: .modified)

            // 게임에 장르 연결 (중복 체크)
            if !realmGame.genres.contains(where: { $0.genreId == genre.id }) {
                realmGame.genres.append(realmGenre)
            }
        }

        // Screenshots 저장 (게임 종속 데이터)
        for screenshot in game.screenshots {
            // 기존 스크린샷 체크 (gameId와 screenshotId로)
            let existingScreenshot = realm.objects(RealmScreenshot.self)
                .where({ $0.gameId == game.id && $0.screenshotId == screenshot.id })
                .first

            if existingScreenshot == nil {
                let realmScreenshot = RealmScreenshot(gameId: game.id, screenshot: screenshot)
                realmScreenshot.game = realmGame
                realm.add(realmScreenshot, update: .modified)
            }
        }
    }
}
