//
//  RealmModels.swift
//  GameFinder
//
//  Created by Suji Jang on 10/1/25.
//

import Foundation
import RealmSwift

// MARK: - 통합 Game 모델
final class RealmGame: Object {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted(indexed: true) var gameId: Int // 기존 게임 ID (API ID)
    @Persisted var name: String
    @Persisted var released: String?
    @Persisted var backgroundImage: String?
    @Persisted var rating: Double
    @Persisted var ratingsCount: Int
    @Persisted var metacritic: Int?
    @Persisted var addedAt: Date = Date()

    // Favorite & Notification & Reading 플래그
    @Persisted var isFavorite: Bool = false
    @Persisted var isNotificationEnabled: Bool = false
    @Persisted var isReading: Bool = false
    @Persisted var favoriteAddedAt: Date?
    @Persisted var notificationAddedAt: Date?
    @Persisted var readingAddedAt: Date?
    @Persisted var readingUpdatedAt: Date?

    // Relations - 마스터 테이블 참조
    @Persisted var platforms: List<RealmPlatform>
    @Persisted var genres: List<RealmGenre>

    // Screenshots는 역참조 (LinkingObjects)
    @Persisted(originProperty: "game") var screenshots: LinkingObjects<RealmScreenshot>

    // Realm -> Domain 변환
    func toDomain() -> Game {
        return Game(
            id: gameId,
            name: name,
            released: released,
            backgroundImage: backgroundImage,
            rating: rating,
            ratingsCount: ratingsCount,
            metacritic: metacritic,
            platforms: Array(platforms.map { $0.toDomain() }),
            genres: Array(genres.map { $0.toDomain() }),
            screenshots: Array(screenshots.map { $0.toDomain() }),
            readingUpdatedAt: readingUpdatedAt
        )
    }
}

// MARK: - Platform
final class RealmPlatform: Object {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted(indexed: true) var platformId: Int // 기존 플랫폼 ID (API ID)
    @Persisted var name: String
    @Persisted var slug: String

    // 역참조: 이 플랫폼을 가진 게임들
    @Persisted(originProperty: "platforms") var games: LinkingObjects<RealmGame>

    convenience init(from platform: GamePlatform) {
        self.init()
        self.platformId = platform.id
        self.name = platform.name
        self.slug = platform.slug
    }

    func toDomain() -> GamePlatform {
        return GamePlatform(id: platformId, name: name, slug: slug)
    }
}

// MARK: - Genre
final class RealmGenre: Object {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted(indexed: true) var genreId: Int // 기존 장르 ID (API ID)
    @Persisted var name: String
    @Persisted var slug: String

    // 역참조: 이 장르를 가진 게임들
    @Persisted(originProperty: "genres") var games: LinkingObjects<RealmGame>

    convenience init(from genre: GameGenre) {
        self.init()
        self.genreId = genre.id
        self.name = genre.name
        self.slug = genre.slug
    }

    func toDomain() -> GameGenre {
        return GameGenre(id: genreId, name: name, slug: slug)
    }
}

// MARK: - Screenshot (게임 종속 데이터)
final class RealmScreenshot: Object {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted(indexed: true) var screenshotId: Int // 스크린샷 ID (API ID)
    @Persisted var gameId: Int // 게임 ID
    @Persisted var image: String
    @Persisted var game: RealmGame? // 역참조를 위한 게임 관계

    convenience init(gameId: Int, screenshot: GameScreenshot) {
        self.init()
        self.gameId = gameId
        self.screenshotId = screenshot.id
        self.image = screenshot.image
    }

    func toDomain() -> GameScreenshot {
        return GameScreenshot(id: screenshotId, image: image)
    }
}

// MARK: - DiaryMedia (일기 미디어)
final class RealmDiaryMedia: Object {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var filePath: String // 파일 경로 (Documents/DiaryImages/UUID.jpg)
    @Persisted var type: String // "image" 또는 "video"
    @Persisted var createdAt: Date

    convenience init(filePath: String, type: String) {
        self.init()
        self.filePath = filePath
        self.type = type
        self.createdAt = Date()
    }
}

// MARK: - Diary (게임 일기)
final class RealmDiary: Object {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted(indexed: true) var gameId: Int // 게임 ID
    @Persisted var title: String
    @Persisted var content: String
    @Persisted var mediaItems: List<RealmDiaryMedia> // 여러 미디어 파일
    @Persisted var createdAt: Date
    @Persisted var updatedAt: Date

    convenience init(gameId: Int, title: String, content: String) {
        self.init()
        self.gameId = gameId
        self.title = title
        self.content = content
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
