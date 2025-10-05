//
//  ReadingManager.swift
//  GameFinder
//
//  Created by Claude on 10/5/25.
//

import Foundation
import RxSwift

final class ReadingManager {
    static let shared = ReadingManager()

    private let repository: RealmGameRepository

    // 게임 기록 상태 변경을 알리는 Subject (gameId, isReading)
    let readingStatusChanged = PublishSubject<(Int, Bool)>()

    private init() {
        repository = RealmGameRepository()
    }

    // MARK: - Add Reading
    func addReading(_ game: Game) -> Bool {
        guard repository.saveOrUpdateGame(game) else {
            return false
        }

        guard repository.updateReading(gameId: game.id, isReading: true) else {
            return false
        }

        readingStatusChanged.onNext((game.id, true))
        return true
    }

    // MARK: - Remove Reading
    func removeReading(gameId: Int) -> Bool {
        guard repository.updateReading(gameId: gameId, isReading: false) else {
            return false
        }

        _ = repository.deleteGameIfUnused(gameId: gameId)

        readingStatusChanged.onNext((gameId, false))
        return true
    }

    // MARK: - Check if Reading
    func isReading(gameId: Int) -> Bool {
        guard let realmGame = repository.findGameById(gameId) else {
            return false
        }
        return realmGame.isReading
    }

    // MARK: - Get All Readings
    func getAllReadings() -> [Game] {
        return repository.findReadings()
    }

    // MARK: - Observe Readings (Rx)
    func observeReadings() -> Observable<[Game]> {
        return repository.observeReadings()
    }
}
