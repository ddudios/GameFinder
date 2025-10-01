////
////  RealmModels.swift
////  GameFinder
////
////  Created by Suji Jang on 10/1/25.
////
//
//import Foundation
//import RealmSwift
//
//// MARK: - Game (Main Entity)
//final class Game: Object {
//    @Persisted(primaryKey: true) var id: Int
//    @Persisted var name: String
//    @Persisted var released: String?
//    @Persisted var backgroundImage: String?
//    @Persisted var rating: Double
//    @Persisted var ratingsCount: Int
//    @Persisted var metacritic: Int?
//    @Persisted var descriptionText: String?
//    @Persisted var playtime: Int
//    @Persisted var cachedAt: Date
//    
//    // Relations
//    @Persisted var platforms: List<GamePlatform>
//    @Persisted var genres: List<GameGenre>
//    @Persisted var screenshots: List<GameScreenshot>
//    @Persisted var developers: List<GameDeveloper>
//    @Persisted var publishers: List<GamePublisher>
//    
//    // User Data
//    @Persisted var isInWishlist: Bool = false
//    @Persisted var isPlaying: Bool = false
//    @Persisted var addedToWishlistAt: Date?
//    @Persisted var startedPlayingAt: Date?
//    
//    convenience init(from response: GameResponse) {
//        self.init()
//        self.id = response.id
//        self.name = response.name
//        self.released = response.released
//        self.backgroundImage = response.backgroundImage
//        self.rating = response.rating
//        self.ratingsCount = response.ratingsCount
//        self.metacritic = response.metacritic
//        self.cachedAt = Date()
//        
//        if let platforms = response.platforms {
//            self.platforms.append(objectsIn: platforms.map { GamePlatform(from: $0.platform) })
//        }
//        
//        if let genres = response.genres {
//            self.genres.append(objectsIn: genres.map { GameGenre(from: $0) })
//        }
//        
//        if let screenshots = response.shortScreenshots {
//            self.screenshots.append(objectsIn: screenshots.map { GameScreenshot(from: $0) })
//        }
//    }
//    
//    convenience init(from response: GameDetailResponse) {
//        self.init()
//        self.id = response.id
//        self.name = response.name
//        self.released = response.released
//        self.backgroundImage = response.backgroundImage
//        self.rating = response.rating
//        self.ratingsCount = response.ratingsCount
//        self.metacritic = response.metacritic
//        self.descriptionText = response.descriptionRaw
//        self.playtime = response.playtime
//        self.cachedAt = Date()
//        
//        if let platforms = response.platforms {
//            self.platforms.append(objectsIn: platforms.map { GamePlatform(from: $0.platform) })
//        }
//        
//        if let genres = response.genres {
//            self.genres.append(objectsIn: genres.map { GameGenre(from: $0) })
//        }
//        
//        if let developers = response.developers {
//            self.developers.append(objectsIn: developers.map { GameDeveloper(from: $0) })
//        }
//        
//        if let publishers = response.publishers {
//            self.publishers.append(objectsIn: publishers.map { GamePublisher(from: $0) })
//        }
//    }
//}
//
//// MARK: - Hashable Conformance
//extension Game: Hashable {
//    static func == (lhs: Game, rhs: Game) -> Bool {
//        return lhs.id == rhs.id
//    }
//    
//    func hash(into hasher: inout Hasher) {
//        hasher.combine(id)
//    }
//}
//
//// MARK: - Platform
//final class GamePlatform: Object {
//    @Persisted var id: Int
//    @Persisted var name: String
//    @Persisted var slug: String
//    
//    convenience init(from platform: Platform) {
//        self.init()
//        self.id = platform.id
//        self.name = platform.name
//        self.slug = platform.slug
//    }
//}
//
//// MARK: - Genre
//final class GameGenre: Object {
//    @Persisted var id: Int
//    @Persisted var name: String
//    @Persisted var slug: String
//    
//    convenience init(from genre: Genre) {
//        self.init()
//        self.id = genre.id
//        self.name = genre.name
//        self.slug = genre.slug
//    }
//}
//
//// MARK: - Screenshot
//final class GameScreenshot: Object {
//    @Persisted var id: Int
//    @Persisted var image: String
//    
//    convenience init(from screenshot: Screenshot) {
//        self.init()
//        self.id = screenshot.id
//        self.image = screenshot.image
//    }
//}
//
//// MARK: - Developer
//final class GameDeveloper: Object {
//    @Persisted var id: Int
//    @Persisted var name: String
//    @Persisted var slug: String
//    
//    convenience init(from developer: Developer) {
//        self.init()
//        self.id = developer.id
//        self.name = developer.name
//        self.slug = developer.slug
//    }
//}
//
//// MARK: - Publisher
//final class GamePublisher: Object {
//    @Persisted var id: Int
//    @Persisted var name: String
//    @Persisted var slug: String
//    
//    convenience init(from publisher: Publisher) {
//        self.init()
//        self.id = publisher.id
//        self.name = publisher.name
//        self.slug = publisher.slug
//    }
//}
//
//// MARK: - Game Diary
//final class GameDiary: Object {
//    @Persisted(primaryKey: true) var id: String = UUID().uuidString
//    @Persisted var gameId: Int
//    @Persisted var gameName: String
//    @Persisted var gameImageURL: String?
//    @Persisted var content: String
//    @Persisted var playtime: Int // minutes
//    @Persisted var createdAt: Date
//    @Persisted var updatedAt: Date
//    @Persisted var isDeleted: Bool = false
//    @Persisted var deletedAt: Date?
//    
//    convenience init(gameId: Int, gameName: String, gameImageURL: String?, content: String, playtime: Int) {
//        self.init()
//        self.gameId = gameId
//        self.gameName = gameName
//        self.gameImageURL = gameImageURL
//        self.content = content
//        self.playtime = playtime
//        self.createdAt = Date()
//        self.updatedAt = Date()
//    }
//}
