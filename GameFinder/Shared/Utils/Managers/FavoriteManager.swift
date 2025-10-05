//
//  FavoriteManager.swift
//  GameFinder
//
//  Created by Claude on 10/5/25.
//

import Foundation
import RealmSwift
import RxSwift

final class FavoriteManager {
    static let shared = FavoriteManager()

    private let realm: Realm

    // 좋아요 상태 변경을 알리는 Subject (gameId, isFavorite)
    let favoriteStatusChanged = PublishSubject<(Int, Bool)>()

    private init() {
        do {
            realm = try Realm()
        } catch {
            fatalError("Realm initialization failed: \(error)")
        }
    }

    // MARK: - Add Favorite
    func addFavorite(_ game: Game) -> Bool {
        do {
            try realm.write {
                let favoriteGame = FavoriteGame(from: game)
                realm.add(favoriteGame, update: .modified)
            }
            favoriteStatusChanged.onNext((game.id, true))
            return true
        } catch {
            print("Failed to add favorite: \(error)")
            return false
        }
    }

    // MARK: - Remove Favorite
    func removeFavorite(gameId: Int) -> Bool {
        do {
            guard let favoriteGame = realm.object(ofType: FavoriteGame.self, forPrimaryKey: gameId) else {
                return false
            }
            try realm.write {
                realm.delete(favoriteGame)
            }
            favoriteStatusChanged.onNext((gameId, false))
            return true
        } catch {
            print("Failed to remove favorite: \(error)")
            return false
        }
    }

    // MARK: - Check if Favorite
    func isFavorite(gameId: Int) -> Bool {
        return realm.object(ofType: FavoriteGame.self, forPrimaryKey: gameId) != nil
    }

    // MARK: - Get All Favorites
    func getAllFavorites() -> [Game] {
        let favorites = realm.objects(FavoriteGame.self)
            .sorted(byKeyPath: "addedAt", ascending: false)
        return Array(favorites.map { $0.toDomain() })
    }

    // MARK: - Observe Favorites (Rx)
    func observeFavorites() -> Observable<[Game]> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onCompleted()
                return Disposables.create()
            }

            let results = self.realm.objects(FavoriteGame.self)
                .sorted(byKeyPath: "addedAt", ascending: false)

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

    // MARK: - Toggle Favorite
    func toggleFavorite(_ game: Game) -> Bool {
        if isFavorite(gameId: game.id) {
            return removeFavorite(gameId: game.id)
        } else {
            return addFavorite(game)
        }
    }
}
