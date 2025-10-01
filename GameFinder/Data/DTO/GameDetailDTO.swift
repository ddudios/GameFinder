//
//  GameDetailDTO.swift
//  GameFinder
//
//  Created by Suji Jang on 10/1/25.
//

import Foundation

// MARK: - 게임 상세 DTO (RAWG API 응답 매핑 전용)
struct GameDetailDTO: Decodable {
    let id: Int                        // 게임 고유 ID
    let name: String                   // 게임 이름
    let description: String?            // HTML 설명 (nullable)
    let metacritic: Int?                // 메타크리틱 점수 (평균)
    let released: String?               // 출시일 (yyyy-MM-dd)
    let tba: Bool                       // 출시일 미정 여부
    let updated: String?                // 데이터 최종 업데이트 시간
    let website: String?                // 공식 웹사이트
    let rating: Double                  // 유저 평점 평균
    let ratingTop: Int                  // 평점 최대값 (보통 5)
    let ratings: [RatingDTO]            // 평점 분포 (exceptional, meh 등)
    let added: Int                      // 라이브러리에 추가된 유저 수
    let playtime: Int                   // 평균 플레이 시간
    let platforms: [PlatformWrapperDTO] // 지원 플랫폼 정보
    let stores: [StoreWrapperDTO]       // 구매 가능한 스토어 정보
    let developers: [DeveloperDTO]      // 개발사 정보
    let genres: [GenreDTO]              // 장르 정보
    let tags: [TagDTO]                  // 태그 정보
    let esrbRating: ESRBRatingDTO?      // ESRB 연령 등급 (nullable)
    let backgroundImage: String?
    let backgroundImageAdditional: String?

    enum CodingKeys: String, CodingKey {
        case id, name, description, metacritic, released, tba, updated, website, rating, ratings, added, playtime, platforms, stores, developers, genres, tags
        case ratingTop = "rating_top"
        case esrbRating = "esrb_rating"
        case backgroundImage = "background_image"
        case backgroundImageAdditional = "background_image_additional"
    }
}

// MARK: - 유저 평점 상세 (예: exceptional, recommended 등)
struct RatingDTO: Decodable {
    let id: Int             // 평점 ID
    let title: String       // 평점 카테고리 이름
    let count: Int          // 카테고리에 속한 평가 수
    let percent: Double     // 비율 (%)
}

// MARK: - 플랫폼 (플랫폼 정보 + 출시일)
struct PlatformWrapperDTO: Decodable {
    let platform: PlatformDTO  // 플랫폼 자체 정보
    let releasedAt: String?    // 해당 플랫폼에서의 출시일
    
    enum CodingKeys: String, CodingKey {
        case platform
        case releasedAt = "released_at"
    }
}

struct PlatformDTO: Decodable {
    let id: Int         // 플랫폼 ID
    let name: String    // 플랫폼 이름 (예: PlayStation 5)
    let slug: String    // 플랫폼 슬러그 (예: playstation5)
}

// MARK: - 스토어 (구매처 정보)
struct StoreWrapperDTO: Decodable {
    let store: StoreDTO // 스토어 자체 정보
}

struct StoreDTO: Decodable {
    let id: Int         // 스토어 ID
    let name: String    // 스토어 이름 (Steam, Xbox 등)
    let slug: String    // 스토어 슬러그
}

// MARK: - 개발사
struct DeveloperDTO: Codable {
    let id: Int         // 개발사 ID
    let name: String    // 개발사 이름
    let slug: String    // 개발사 슬러그
}

// MARK: - 장르
struct GenreDTO: Decodable {
    let id: Int         // 장르 ID
    let name: String    // 장르 이름 (Action, RPG 등)
    let slug: String    // 장르 슬러그
}

// MARK: - 태그 (게임의 특징 키워드)
struct TagDTO: Decodable {
    let id: Int         // 태그 ID
    let name: String    // 태그 이름 (Singleplayer, Open World 등)
    let slug: String    // 태그 슬러그
}

// MARK: - ESRB 연령 등급
struct ESRBRatingDTO: Decodable {
    let id: Int         // ESRB 등급 ID
    let name: String    // 등급 이름 (Mature 등)
    let slug: String    // 등급 슬러그 (mature 등)
}

extension GameDetailDTO {
    func toDomain() -> Game {
        return Game(
            id: id,
            title: name,
            description: description ?? "설명이 없습니다.",
            metacritic: metacritic,
            releaseDate: released.flatMap {
                let df = DateFormatter()
                df.dateFormat = "yyyy-MM-dd"
                return df.date(from: $0)
            },
            website: website.flatMap(URL.init(string:)),
            rating: rating,
            ratingTop: ratingTop,
            added: added,
            playtime: playtime,
            platforms: platforms.map { $0.platform.name },
            stores: stores.map { $0.store.name },
            developers: developers.map { $0.name },
            genres: genres.map { $0.name },
            tags: tags.map { $0.name },
            esrb: esrbRating?.name,
            backgroundImageURL: backgroundImage   // 🔹 매핑
        )
    }
}
