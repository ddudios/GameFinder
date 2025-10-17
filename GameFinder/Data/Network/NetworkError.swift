//
//  NetworkError.swift
//  GameFinder
//
//  Created by Suji Jang on 10/1/25.
//

import Foundation

enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case noData
    case decodingFailed
    case apiLimitExceeded
    case notFound
    case serverError(Int)
    case server(message: String)
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return L10n.Error.invalidURL
        case .invalidResponse:
            return L10n.Error.invalidResponse
        case .noData:
            return L10n.Error.noData
        case .decodingFailed:
            return L10n.Error.decodingFailed
        case .apiLimitExceeded:
            return L10n.Error.apiLimitExceeded
        case .notFound:
            return L10n.Error.notFound
        case .serverError(let code):
            print("서버 오류가 발생했습니다. (코드: \(code))")
            return L10n.Error.server
        case .server(let message):
            print("서버 오류: \(message)")
            return L10n.Error.server
        case .unknown:
            return L10n.Error.unknown
        }
    }
}
