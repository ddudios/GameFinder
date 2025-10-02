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
    
    case popular(page: Int = 1, pageSize: Int = 10)
    case freeToPlay(page: Int = 1, pageSize: Int = 10)
    
    case search(query: String, page: Int = 1)      // 검색: /games?search=
    case upcoming(start: String, end: String,
                  page: Int = 1, pageSize: Int = 20) // 기간 내 출시: /games?dates=YYYY-MM-DD,YYYY-MM-DD

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
        case .popular, .freeToPlay, .search, .upcoming:
            return "/games"
        }
    }

    // MARK: - Query Parameters
    private var parameters: [String: Any] {
        switch self {
        case .game:
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

        case let .search(query, page):
            return [
                "search": query,
                "page": page,
                "page_size": 20
            ]

        case let .upcoming(start, end, page, pageSize):
            return [
                "dates": "\(start),\(end)",  // 예: "2025-10-01,2026-10-01"
                "ordering": "released",
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
