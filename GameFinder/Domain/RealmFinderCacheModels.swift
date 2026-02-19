//
//  RealmFinderCacheModels.swift
//  GameFinder
//
//  Created by Codex on 2/18/26.
//

import Foundation
import RealmSwift

final class RealmFinderSectionCacheMeta: Object {
    @Persisted(primaryKey: true) var sectionKey: String
    @Persisted var fetchedAt: Date = Date()
    @Persisted var ttlSeconds: Int = 0
}

final class RealmFinderSectionItem: Object {
    @Persisted(primaryKey: true) var id: String
    @Persisted(indexed: true) var sectionKey: String
    @Persisted var sortOrder: Int

    @Persisted(indexed: true) var gameId: Int
    @Persisted var name: String
    @Persisted var released: String?
    @Persisted var backgroundImage: String?
    @Persisted var rating: Double
    @Persisted var ratingsCount: Int
    @Persisted var metacritic: Int?
    @Persisted var genresJSON: String = "[]"
}
