//
//  NetworkManager.swift
//  GameFinder
//
//  Created by Suji Jang on 10/1/25.
//

import Foundation
import Alamofire

final class NetworkManager {
    private init() { }
    class var isConnectedToInternet: Bool {
        return NetworkReachabilityManager()?.isReachable ?? false
    }
}
