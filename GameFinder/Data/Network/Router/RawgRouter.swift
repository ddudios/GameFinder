//
//  RawgRouter.swift
//  GameFinder
//
//  Created by Suji Jang on 10/1/25.
//

import Foundation
import Alamofire

enum RawgRouter: URLRequestConvertible {
    case game(id: String)                          // 상세 조회: /games/{id}
    case screenshots(id: String)                   // 스크린샷: /games/{id}/screenshots

    case popular(page: Int = 1, pageSize: Int = 10)
    case freeToPlay(page: Int = 1, pageSize: Int = 10)

    case search(query: String, page: Int = 1, platformIds: String? = nil)      // 검색: /games?search=
    case upcoming(start: String, end: String,
                  page: Int = 1, pageSize: Int = 20) // 기간 내 출시: /games?dates=YYYY-MM-DD,YYYY-MM-DD
    case platform(platformName: String, page: Int = 1, pageSize: Int = 20) // 플랫폼별 게임

    // MARK: - Base
    private var baseURL: URL {
        URL(string: Bundle.getAPIKey(for: .rawgBaseUrl))!
    }
    private var apiKey: String {
        Bundle.getAPIKey(for: .rawgClientKey)
    }

    // MARK: - HTTP Method
    var method: HTTPMethod { .get }

    // MARK: - Path
    private var path: String {
        switch self {
        case let .game(id):
            return "/games/\(id)"
        case let .screenshots(id):
            return "/games/\(id)/screenshots"
        case .popular, .freeToPlay, .search, .upcoming, .platform:
            return "/games"
        }
    }

    // MARK: - Query Parameters
    private var parameters: [String: Any] {
        switch self {
        case .game, .screenshots:
            return [:]
            
        case let .popular(page, pageSize):
            return [
                "ordering": "-added",  // 가장 많이 추가된 게임
                "page": page,
                "page_size": pageSize
            ]
            
        case let .freeToPlay(page, pageSize):
            return [
                "tags": "79",  // Free to Play 태그
                "page": page,
                "page_size": pageSize
            ]

        case let .search(query, page, platformIds):
            var params: [String: Any] = [
                "search": query,
                "page": page,
                "page_size": 20
            ]
            if let platformIds, !platformIds.isEmpty {
                params["platforms"] = platformIds
            }
            return params

        case let .upcoming(start, end, page, pageSize):
            return [
                "dates": "\(start),\(end)",  // 예: "2025-10-01,2026-10-01"
                "ordering": "released",
                "page": page,
                "page_size": pageSize
            ]

        case let .platform(platformName, page, pageSize):
            // 플랫폼 이름을 ID로 변환
            let platformIds: String
            switch platformName.lowercased() {
            case "steam", "pc":
                platformIds = "4" // PC
            case "playstation":
                platformIds = "187,18,16" // PS5, PS4, PS3
            case "nintendo":
                platformIds = "7,8,9" // Switch, Wii U, Wii
            case "mobile":
                platformIds = "21,3" // Android, iOS
            default:
                platformIds = "4" // 기본값: PC
            }

            return [
                "platforms": platformIds,
                "ordering": "-added",
                "page": page,
                "page_size": pageSize
            ]
        }
    }

    // MARK: - URLRequestConvertible
    func asURLRequest() throws -> URLRequest {
        let url = baseURL.appendingPathComponent(path)

        var request = URLRequest(url: url)
        request.method = method

        // 모든 요청에 RAWG API key 공통 부착
        var allParams = parameters
        allParams["key"] = apiKey

        // GET 쿼리 인코딩
        return try URLEncoding(destination: .queryString).encode(request, with: allParams)
    }
}
