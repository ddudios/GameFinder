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
    }
}
