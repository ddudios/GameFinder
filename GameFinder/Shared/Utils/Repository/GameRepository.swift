//
//  GameRepository.swift
//  GameFinder
//
//  Created by Suji Jang on 10/6/25.
//

import Foundation
import RealmSwift
import RxSwift

protocol GameRepository {
    associatedtype Item

    // MARK: - Create & Update
    func saveOrUpdateGame(_ game: Game) -> Bool

    // MARK: - Read
    func findGameById(_ gameId: Int) -> Item?
    func findFavorites() -> [Game]
    func findNotifications() -> [Game]
    func findReadings() -> [Game]

    // MARK: - Observe
    func observeFavorites() -> Observable<[Game]>
    func observeNotifications() -> Observable<[Game]>
    func observeReadings() -> Observable<[Game]>

    // MARK: - Update Flags
    func updateFavorite(gameId: Int, isFavorite: Bool) -> Bool
    func updateNotification(gameId: Int, isEnabled: Bool) -> Bool
    func updateReading(gameId: Int, isReading: Bool) -> Bool

    // MARK: - Delete
    func deleteGameIfUnused(gameId: Int) -> Bool

    // MARK: - Count
    func countGames() -> Int
}
