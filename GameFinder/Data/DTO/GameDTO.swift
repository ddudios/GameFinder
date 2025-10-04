//
//  GameDTO.swift
//  GameFinder
//
//  Created by Suji Jang on 10/1/25.
//

import Foundation

// MARK: - Game List DTO (게임 목록 응답)
struct GameListDTO: Decodable {
    let count: Int          // 전체 게임 수
    let next: String?       // 다음 페이지 URL
    let previous: String?   // 이전 페이지 URL
    let results: [GameDTO]  // 게임 목록
}

// MARK: - Game DTO (목록용 - 간단한 정보)
struct GameDTO: Decodable {
    let id: Int                     // 게임 고유 ID
    let name: String                // 게임 이름
    let released: String?           // 출시일 (yyyy-MM-dd)
    let backgroundImage: String?    // 썸네일 이미지 URL
    let rating: Double              // 평점 (0.0 ~ 5.0)
    let ratingsCount: Int           // 평점 참여자 수
    let metacritic: Int?            // 메타크리틱 점수 (0 ~ 100)
    let platforms: [PlatformInfo]?  // 지원 플랫폼 목록
    let genres: [Genre]?            // 장르 목록
    let shortScreenshots: [Screenshot]? // 스크린샷 목록 (미리보기용)
    
    enum CodingKeys: String, CodingKey {
        case id, name, released, rating, metacritic, platforms, genres
        case backgroundImage = "background_image"
        case ratingsCount = "ratings_count"
        case shortScreenshots = "short_screenshots"
    }
}

// MARK: - Platform Info (플랫폼 래퍼)
struct PlatformInfo: Decodable {
    let platform: Platform  // 플랫폼 정보
}

// MARK: - Platform (플랫폼 상세)
struct Platform: Decodable {
    let id: Int         // 플랫폼 ID
    let name: String    // 플랫폼 이름 (예: PlayStation 5)
    let slug: String    // 플랫폼 슬러그 (예: playstation5)
}

// MARK: - Genre (장르)
struct Genre: Decodable {
    let id: Int         // 장르 ID
    let name: String    // 장르 이름 (예: Action, RPG)
    let slug: String    // 장르 슬러그 (예: action, role-playing-games-rpg)
}

// MARK: - Screenshot (스크린샷)
struct Screenshot: Decodable {
    let id: Int         // 스크린샷 ID
    let image: String   // 스크린샷 이미지 URL
}

// MARK: - Game Detail DTO (상세용 - 모든 정보)
struct GameDetailDTO: Decodable {
    let id: Int                         // 게임 고유 ID
    let name: String                    // 게임 이름
    let nameOriginal: String?           // 원제 (예: 한글명이 있을 경우 영문명)
    let description: String?            // HTML 형식 설명
    let descriptionRaw: String?         // 순수 텍스트 설명
    let released: String?               // 출시일 (yyyy-MM-dd)
    let backgroundImage: String?        // 메인 배경 이미지 URL
    let backgroundImageAdditional: String? // 추가 배경 이미지 URL
    let rating: Double?                 // 평점 (0.0 ~ 5.0)
    let ratingsCount: Int?              // 평점 참여자 수
    let metacritic: Int?                // 메타크리틱 점수 (0 ~ 100)
    let playtime: Int?                  // 평균 플레이 타임 (시간)
    let platforms: [PlatformInfo]?      // 지원 플랫폼 목록
    let genres: [Genre]?                // 장르 목록
    let developers: [Developer]?        // 개발사 목록
    let publishers: [Publisher]?        // 퍼블리셔 목록
    let tags: [Tag]?                    // 태그 목록 (특징 키워드)
    let esrbRating: ESRBRating?         // ESRB 연령 등급

    enum CodingKeys: String, CodingKey {
        case id, name, description, released, rating, metacritic, playtime, platforms, genres, developers, publishers, tags
        case nameOriginal = "name_original"
        case descriptionRaw = "description_raw"
        case backgroundImage = "background_image"
        case backgroundImageAdditional = "background_image_additional"
        case ratingsCount = "ratings_count"
        case esrbRating = "esrb_rating"
    }
}

// MARK: - Developer (개발사)
struct Developer: Decodable {
    let id: Int         // 개발사 ID
    let name: String    // 개발사 이름 (예: FromSoftware)
    let slug: String    // 개발사 슬러그 (예: fromsoftware)
}

// MARK: - Publisher (퍼블리셔)
struct Publisher: Decodable {
    let id: Int         // 퍼블리셔 ID
    let name: String    // 퍼블리셔 이름 (예: Bandai Namco)
    let slug: String    // 퍼블리셔 슬러그 (예: bandai-namco)
}

// MARK: - Tag (태그 - 게임 특징)
struct Tag: Decodable {
    let id: Int         // 태그 ID
    let name: String    // 태그 이름 (예: Singleplayer, Open World)
    let slug: String    // 태그 슬러그 (예: singleplayer, open-world)
}

// MARK: - ESRB Rating (연령 등급)
struct ESRBRating: Decodable {
    let id: Int         // 등급 ID
    let name: String    // 등급 이름 (예: Mature, Everyone)
    let slug: String    // 등급 슬러그 (예: mature, everyone)
}

// MARK: - Screenshots DTO (스크린샷 목록 응답)
struct ScreenshotsDTO: Decodable {
    let count: Int              // 전체 스크린샷 수
    let results: [Screenshot]   // 스크린샷 목록
}
