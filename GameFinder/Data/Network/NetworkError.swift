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
            return "유효하지 않은 URL입니다."
        case .invalidResponse:
            return "서버 응답이 올바르지 않습니다."
        case .noData:
            return "데이터를 받지 못했습니다."
        case .decodingFailed:
            return "데이터 변환에 실패했습니다."
        case .apiLimitExceeded:
            return "API 호출 한도를 초과했습니다. 잠시 후 다시 시도해주세요."
        case .notFound:
            return "요청한 데이터를 찾을 수 없습니다."
        case .serverError(let code):
            return "서버 오류가 발생했습니다. (코드: \(code))"
        case .server(let message):
            return "서버 오류: \(message)"
        case .unknown:
            return "알 수 없는 오류가 발생했습니다."
        }
    }
}
