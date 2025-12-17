//
//  SharedWidgetGame.swift
//  GameFinder
//
//  Shared model for Widget and App communication via App Group
//  ⚠️ This file must be included in BOTH App and Widget Extension targets
//

import Foundation

// MARK: - Shared Widget Data
/// 위젯과 앱 간 공유되는 전체 데이터 구조
struct SharedWidgetData: Codable {
    let games: [SharedWidgetGame]
    let lastUpdated: Date
}

// MARK: - Shared Widget Game
/// 위젯에 표시할 게임 정보 (최소한의 필수 데이터만)
struct SharedWidgetGame: Codable, Identifiable {
    let id: Int
    let title: String
    let platform: String
    let genre: String
    let releaseDate: Date
    let imageURL: String?

    /// App Group 컨테이너에 저장된 로컬 이미지 파일명
    var localImageFileName: String? {
        imageURL != nil ? "game_\(id).jpg" : nil
    }
}

// MARK: - Conversion from DTO
extension SharedWidgetGame {
    /// GameDTO를 SharedWidgetGame으로 변환
    /// - Parameters:
    ///   - dto: RAWG API에서 받은 GameDTO
    /// - Returns: 위젯용으로 변환된 SharedWidgetGame
    static func from(dto: GameDTO) -> SharedWidgetGame {
        let platformName = dto.platforms?.first?.platform.name ?? "Unknown"
        let genreNames = dto.genres?.prefix(2).map { $0.name }.joined(separator: ", ") ?? "Unknown"

        let releaseDate: Date
        if let releasedString = dto.released {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            releaseDate = formatter.date(from: releasedString) ?? Date()
        } else {
            releaseDate = Date()
        }

        return SharedWidgetGame(
            id: dto.id,
            title: dto.name,
            platform: platformName,
            genre: genreNames,
            releaseDate: releaseDate,
            imageURL: dto.backgroundImage
        )
    }
}
