//
//  CheapSharkRouter.swift
//  GameFinder
//
//  Created by Codex on 2/28/26.
//

import Foundation
import Alamofire

enum CheapSharkRouter: URLRequestConvertible {
    case deals(
        pageNumber: Int,
        pageSize: Int,
        sortBy: String = "Savings",
        descending: Bool = true,
        onSaleOnly: Bool = false
    )
    case stores

    private var baseURL: URL {
        URL(string: "https://www.cheapshark.com/api/1.0")!
    }

    private var method: HTTPMethod { .get }

    private var path: String {
        switch self {
        case .deals:
            return "/deals"
        case .stores:
            return "/stores"
        }
    }

    private var parameters: [String: Any] {
        switch self {
        case let .deals(pageNumber, pageSize, sortBy, descending, onSaleOnly):
            return [
                "pageNumber": pageNumber,
                "pageSize": pageSize,
                "sortBy": sortBy,
                "desc": descending ? 1 : 0,
                "onSale": onSaleOnly ? 1 : 0
            ]
        case .stores:
            return [:]
        }
    }

    func asURLRequest() throws -> URLRequest {
        let url = baseURL.appendingPathComponent(path)

        var request = URLRequest(url: url)
        request.method = method

        return try URLEncoding(destination: .queryString).encode(request, with: parameters)
    }
}
