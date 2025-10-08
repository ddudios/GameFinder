//
//  Game.swift
//  GameFinder
//
//  Created by Suji Jang on 10/1/25.
//

import Foundation

// MARK: - Game (Domain Model)
struct Game: Hashable {
    let id: Int // API에서 제공하는 고유 ID
    let name: String
    let released: String?
    let backgroundImage: String?
    let rating: Double
    let ratingsCount: Int
    let metacritic: Int?
    let platforms: [GamePlatform]
    let genres: [GameGenre]
    let screenshots: [GameScreenshot]
    let readingUpdatedAt: Date? // 게임 기록 최신 업데이트 날짜

    // MARK: - Hashable 구현
    // DiffableDataSource는 이 메서드로 아이템을 구분합니다
    func hash(into hasher: inout Hasher) {
        hasher.combine(id) // API의 고유 ID로 구분
    }

    // 두 게임이 같은지 비교 (id만 비교)
    static func == (lhs: Game, rhs: Game) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - GamePlatform
struct GamePlatform: Hashable {
    let id: Int
    let name: String
    let slug: String
}

// MARK: - GameGenre
struct GameGenre: Hashable {
    let id: Int
    let name: String
    let slug: String
}

// MARK: - GameScreenshot
struct GameScreenshot: Hashable {
    let id: Int
    let image: String
}

// MARK: - GameDetail (Domain Model for Detail View)
struct GameDetail {
    let id: Int
    let name: String
    let nameOriginal: String?
    let description: String?
    let descriptionRaw: String?
    let released: String?
    let backgroundImage: String?
    let backgroundImageAdditional: String?
    let rating: Double?
    let ratingsCount: Int?
    let metacritic: Int?
    let playtime: Int?
    let platforms: [GamePlatform]
    let genres: [GameGenre]
    let developers: [GameDeveloper]
    let publishers: [GamePublisher]
    let tags: [GameTag]
    let esrbRating: GameESRBRating?
}

// MARK: - GameDeveloper
struct GameDeveloper: Hashable {
    let id: Int
    let name: String
    let slug: String
}

// MARK: - GamePublisher
struct GamePublisher: Hashable {
    let id: Int
    let name: String
    let slug: String
}

// MARK: - GameTag
struct GameTag: Hashable {
    let id: Int
    let name: String
    let slug: String
}

// MARK: - GameESRBRating
struct GameESRBRating: Hashable {
    let id: Int
    let name: String
    let slug: String
}

// MARK: - Response → Domain 변환
extension Game {
    init(from response: GameDTO) {
        self.id = response.id
        self.name = response.name
        self.released = response.released
        self.backgroundImage = response.backgroundImage
        self.rating = response.rating
        self.ratingsCount = response.ratingsCount
        self.metacritic = response.metacritic

        // Platform 변환
        self.platforms = response.platforms?.map { platformInfo in
            GamePlatform(
                id: platformInfo.platform.id,
                name: platformInfo.platform.name,
                slug: platformInfo.platform.slug
            )
        } ?? []

        // Genre 변환
        self.genres = response.genres?.map { genre in
            GameGenre(
                id: genre.id,
                name: genre.name,
                slug: genre.slug
            )
        } ?? []

        // Screenshot 변환
        self.screenshots = response.shortScreenshots?.map { screenshot in
            GameScreenshot(
                id: screenshot.id,
                image: screenshot.image
            )
        } ?? []

        // API 응답에는 readingUpdatedAt이 없으므로 nil
        self.readingUpdatedAt = nil
    }
}

extension GameDetail {
    init(from response: GameDetailDTO) {
        self.id = response.id
        self.name = response.name
        self.nameOriginal = response.nameOriginal
        self.description = response.description
        self.descriptionRaw = response.descriptionRaw
        self.released = response.released
        self.backgroundImage = response.backgroundImage
        self.backgroundImageAdditional = response.backgroundImageAdditional
        self.rating = response.rating
        self.ratingsCount = response.ratingsCount
        self.metacritic = response.metacritic
        self.playtime = response.playtime

        // Platform 변환
        self.platforms = response.platforms?.map { platformInfo in
            GamePlatform(
                id: platformInfo.platform.id,
                name: platformInfo.platform.name,
                slug: platformInfo.platform.slug
            )
        } ?? []

        // Genre 변환
        self.genres = response.genres?.map { genre in
            GameGenre(
                id: genre.id,
                name: genre.name,
                slug: genre.slug
            )
        } ?? []

        // Developer 변환
        self.developers = response.developers?.map { developer in
            GameDeveloper(
                id: developer.id,
                name: developer.name,
                slug: developer.slug
            )
        } ?? []

        // Publisher 변환
        self.publishers = response.publishers?.map { publisher in
            GamePublisher(
                id: publisher.id,
                name: publisher.name,
                slug: publisher.slug
            )
        } ?? []

        // Tag 변환
        self.tags = response.tags?.map { tag in
            GameTag(
                id: tag.id,
                name: tag.name,
                slug: tag.slug
            )
        } ?? []

        // ESRB Rating 변환
        self.esrbRating = response.esrbRating.map { esrb in
            GameESRBRating(
                id: esrb.id,
                name: esrb.name,
                slug: esrb.slug
            )
        }
    }

    // GameDetail을 Game으로 변환
    func toGame() -> Game {
        return Game(
            id: id,
            name: name,
            released: released,
            backgroundImage: backgroundImage,
            rating: rating ?? 0.0,
            ratingsCount: ratingsCount ?? 0,
            metacritic: metacritic,
            platforms: platforms,
            genres: genres,
            screenshots: [], // GameDetail에는 스크린샷 정보가 없으므로 빈 배열
            readingUpdatedAt: nil
        )
    }
}
