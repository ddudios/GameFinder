//
//  NetworkObservable.swift
//  GameFinder
//
//  Created by Suji Jang on 10/1/25.
//

import Foundation
import Alamofire
import RxSwift

final class NetworkObservable {
    private init() { }

    static func request<T: Decodable>(
        router: URLRequestConvertible,
        as type: T.Type
    ) -> Single<Result<T, NetworkError>> {
        return Single.create { observer in

            // API 요청 정보 추출
            let urlRequest = try? router.asURLRequest()
            let endpoint = urlRequest?.url?.path ?? "unknown"
            let method = urlRequest?.httpMethod ?? "unknown"

            // API 요청 시작 로깅
            LogManager.network.info("🌐 API Request: \(method) \(endpoint)")

            let decoder = JSONDecoder()

            let request = AF.request(router)
                .validate(statusCode: 200..<300)
                .responseDecodable(of: T.self, decoder: decoder) { response in
                    switch response.result {
                    case .success(let dto):
                        // API 성공 로깅
                        let statusCode = response.response?.statusCode ?? 0
                        LogManager.network.debug("✅ API Success: \(method) \(endpoint) - Status: \(statusCode)")
                        observer(.success(.success(dto)))

                    case .failure(let error):
                        // API 실패 로깅
                        let statusCode = response.response?.statusCode ?? 0
                        let errorMessage = error.localizedDescription
                        LogManager.network.error("❌ API Failure: \(method) \(endpoint) - Status: \(statusCode), Error: \(errorMessage)")

                        if let data = response.data,
                           let serverMessage = String(data: data, encoding: .utf8) {
                            LogManager.logAPIError(endpoint: endpoint, errorMessage: serverMessage)
                            observer(.success(.failure(.server(message: serverMessage))))
                        } else {
                            LogManager.logAPIError(endpoint: endpoint, errorMessage: errorMessage)
                            observer(.success(.failure(.unknown)))
                        }
                    }
                }

            return Disposables.create { request.cancel() }
        }
    }
}
