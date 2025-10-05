//
//  RealmModels.swift
//  GameFinder
//
//  Created by Suji Jang on 10/1/25.
//

import Foundation
import RealmSwift

// MARK: - FavoriteGame (Realm Model)
final class FavoriteGame: Object {
    @Persisted(primaryKey: true) var id: Int
    @Persisted var name: String
    @Persisted var released: String?
    @Persisted var backgroundImage: String?
    @Persisted var rating: Double
    @Persisted var ratingsCount: Int
    @Persisted var metacritic: Int?
    @Persisted var addedAt: Date

    // Relations
    @Persisted var platforms: List<RealmGamePlatform>
    @Persisted var genres: List<RealmGameGenre>

    convenience init(from game: Game) {
        self.init()
        self.id = game.id
        self.name = game.name
        self.released = game.released
        self.backgroundImage = game.backgroundImage
        self.rating = game.rating
        self.ratingsCount = game.ratingsCount
        self.metacritic = game.metacritic
        self.addedAt = Date()

        self.platforms.append(objectsIn: game.platforms.map { RealmGamePlatform(from: $0) })
        self.genres.append(objectsIn: game.genres.map { RealmGameGenre(from: $0) })
    }

    // Realm -> Domain 변환
    func toDomain() -> Game {
        return Game(
            id: id,
            name: name,
            released: released,
            backgroundImage: backgroundImage,
            rating: rating,
            ratingsCount: ratingsCount,
            metacritic: metacritic,
            platforms: Array(platforms.map { $0.toDomain() }),
            genres: Array(genres.map { $0.toDomain() }),
            screenshots: []
        )
    }
}

// MARK: - Platform
final class RealmGamePlatform: Object {
    @Persisted var id: Int
    @Persisted var name: String
    @Persisted var slug: String

    convenience init(from platform: GamePlatform) {
        self.init()
        self.id = platform.id
        self.name = platform.name
        self.slug = platform.slug
    }

    func toDomain() -> GamePlatform {
        return GamePlatform(id: id, name: name, slug: slug)
    }
}

// MARK: - Genre
final class RealmGameGenre: Object {
    @Persisted var id: Int
    @Persisted var name: String
    @Persisted var slug: String

    convenience init(from genre: GameGenre) {
        self.init()
        self.id = genre.id
        self.name = genre.name
        self.slug = genre.slug
    }

    func toDomain() -> GameGenre {
        return GameGenre(id: id, name: name, slug: slug)
    }
}
