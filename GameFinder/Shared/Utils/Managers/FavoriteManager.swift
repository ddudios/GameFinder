//
//  FavoriteManager.swift
//  GameFinder
//
//  Created by Suji Jang on 10/5/25.
//

import Foundation
import RxSwift

final class FavoriteManager {
    static let shared = FavoriteManager()

    private let repository: RealmGameRepository

    // 좋아요 상태 변경을 알리는 Subject (gameId, isFavorite)
    let favoriteStatusChanged = PublishSubject<(Int, Bool)>()

    private init() {
        repository = RealmGameRepository()
    }

    // MARK: - Add Favorite
    func addFavorite(_ game: Game) -> Bool {
        guard repository.saveOrUpdateGame(game) else {
            LogManager.error.error("Failed to save game for favorite: \(game.id)")
            return false
        }

        guard repository.updateFavorite(gameId: game.id, isFavorite: true) else {
            LogManager.error.error("Failed to update favorite status: \(game.id)")
            return false
        }

        // 로깅 및 Analytics
        LogManager.logAddFavorite(gameId: game.id, gameName: game.name)

        favoriteStatusChanged.onNext((game.id, true))
        return true
    }

    // MARK: - Remove Favorite
    func removeFavorite(gameId: Int) -> Bool {
        guard repository.updateFavorite(gameId: gameId, isFavorite: false) else {
            LogManager.error.error("Failed to remove favorite: \(gameId)")
            return false
        }

        _ = repository.deleteGameIfUnused(gameId: gameId)

        // 로깅 및 Analytics
        LogManager.logRemoveFavorite(gameId: gameId)

        favoriteStatusChanged.onNext((gameId, false))
        return true
    }

    // MARK: - Check if Favorite
    func isFavorite(gameId: Int) -> Bool {
        guard let realmGame = repository.findGameById(gameId) else {
            return false
        }
        return realmGame.isFavorite
    }

    // MARK: - Get All Favorites
    func getAllFavorites() -> [Game] {
        return repository.findFavorites()
    }

    // MARK: - Observe Favorites (Rx)
    func observeFavorites() -> Observable<[Game]> {
        return repository.observeFavorites()
    }

    // MARK: - Toggle Favorite
    @discardableResult
    func toggleFavorite(_ game: Game) -> Bool {
        if isFavorite(gameId: game.id) {
            return removeFavorite(gameId: game.id)
        } else {
            return addFavorite(game)
        }
    }
}
