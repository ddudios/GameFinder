//
//  FinderCacheRepository.swift
//  GameFinder
//
//  Created by Codex on 2/18/26.
//

import Foundation

enum FinderCacheSection: String {
    case upcomingGames
    case freeGames
    case popularGames

    var ttl: TimeInterval {
        7 * 24 * 60 * 60
    }

    var maxItemCount: Int {
        switch self {
        case .upcomingGames:
            return 10
        case .freeGames:
            return 15
        case .popularGames:
            return 10
        }
    }
}

protocol FinderCacheRepository {
    func load(section: FinderCacheSection) -> [Game]
    func save(section: FinderCacheSection, games: [Game], fetchedAt: Date)
    func isFresh(section: FinderCacheSection, now: Date) -> Bool
    func clear(section: FinderCacheSection)
}
