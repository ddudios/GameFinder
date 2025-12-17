//
//  WidgetNetworkManager.swift
//  GameFinderWidget
//
//  Created by Suji Jang on 12/16/25.
//

import Foundation

// MARK: - Widget Game Response
struct WidgetGameResponse: Codable {
    let results: [WidgetGameDTO]
}

struct WidgetGameDTO: Codable {
    let id: Int
    let name: String
    let released: String?
    let backgroundImage: String?
    let platforms: [PlatformInfo]?
    let genres: [GenreDTO]?

    enum CodingKeys: String, CodingKey {
        case id, name, released, platforms, genres
        case backgroundImage = "background_image"
    }
}

struct PlatformInfo: Codable {
    let platform: PlatformDTO
}

struct PlatformDTO: Codable {
    let name: String
}

struct GenreDTO: Codable {
    let name: String
}

// MARK: - Widget Network Manager
final class WidgetNetworkManager {
    static let shared = WidgetNetworkManager()
    private init() {}

    // 위젯용 이미지 저장 디렉토리
    private var imageDirectory: URL {
        let containerURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let directory = containerURL.appendingPathComponent("WidgetImages")

        // 디렉토리가 없으면 생성
        if !FileManager.default.fileExists(atPath: directory.path) {
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }

        return directory
    }

    // 이미지 다운로드 및 로컬 저장
    func downloadAndSaveImage(from urlString: String, gameId: Int) async -> String? {
        guard let url = URL(string: urlString) else { return nil }

        let localFileName = "game_\(gameId).jpg"
        let localURL = imageDirectory.appendingPathComponent(localFileName)

        // 이미 저장된 이미지가 있으면 경로 반환
        if FileManager.default.fileExists(atPath: localURL.path) {
            return localURL.path
        }

        // 이미지 다운로드
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            try data.write(to: localURL)
            return localURL.path
        } catch {
            print("Failed to download image: \(error)")
            return nil
        }
    }

    func fetchUpcomingGames() async throws -> [WidgetGame] {
        // 위젯 자체의 Info.plist에서 API 키 읽기
        guard let baseURL = Bundle.main.object(forInfoDictionaryKey: "RAWGBaseUrl") as? String,
              let apiKey = Bundle.main.object(forInfoDictionaryKey: "RAWGClientKey") as? String,
              !baseURL.isEmpty, !apiKey.isEmpty else {
            print("Failed to load API keys from widget Info.plist")
            print("BaseURL: \(Bundle.main.object(forInfoDictionaryKey: "RAWGBaseUrl") ?? "nil")")
            print("APIKey: \(Bundle.main.object(forInfoDictionaryKey: "RAWGClientKey") ?? "nil")")
            throw URLError(.badURL)
        }

        // 3개월 후부터 6개월간의 출시 예정 게임
        let startDate = Calendar.current.date(byAdding: .month, value: 3, to: Date())!
        let endDate = Calendar.current.date(byAdding: .month, value: 6, to: startDate)!

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let start = dateFormatter.string(from: startDate)
        let end = dateFormatter.string(from: endDate)

        var components = URLComponents(string: "\(baseURL)/games")!
        components.queryItems = [
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "dates", value: "\(start),\(end)"),
            URLQueryItem(name: "ordering", value: "released"),
            URLQueryItem(name: "page_size", value: "20")
        ]

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(WidgetGameResponse.self, from: data)

        // DTO를 WidgetGame으로 변환
        return response.results.map { dto in
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

            return WidgetGame(
                id: dto.id,
                title: dto.name,
                coverImagePath: nil, // 로컬 에셋 사용 안함
                imageURL: dto.backgroundImage, // API에서 받은 이미지 URL
                platform: platformName,
                genre: genreNames,
                releaseDate: releaseDate
            )
        }
    }
}
