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
            
            let decoder = JSONDecoder()
            
            let request = AF.request(router)
                .validate(statusCode: 200..<300)
                .responseDecodable(of: T.self, decoder: decoder) { response in
                    switch response.result {
                    case .success(let dto):
                        observer(.success(.success(dto)))
                        
                    case .failure:
                        if let data = response.data,
                           let serverMessage = String(data: data, encoding: .utf8) {
                            observer(.success(.failure(.server(message: serverMessage))))
                        } else {
                            observer(.success(.failure(.unknown)))
                        }
                    }
                }
            
            return Disposables.create { request.cancel() }
        }
    }
}
