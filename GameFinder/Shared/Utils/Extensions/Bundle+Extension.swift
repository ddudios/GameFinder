//
//  Bundle+Extension.swift
//  GameFinder
//
//  Created by Suji Jang on 10/1/25.
//

import Foundation

enum APIValue: String {
    case rawgBaseUrl = "RAWGBaseUrl"
    case rawgClientKey = "RAWGClientKey"
}

extension Bundle {
    static func getAPIKey(for key: APIValue) -> String {
        guard let filePath = Bundle.main.path(forResource: "Info", ofType: "plist"),
              let plistDict = NSDictionary(contentsOfFile: filePath) else {
            fatalError("error: Couldn't find file 'Info.plist'.")
        }
        
        guard let value = plistDict.object(forKey: key.rawValue) as? String else {
            fatalError("error: Couldn't find key '\(key.rawValue)' in 'Info.plist'.")
        }
        
        return value
    }
}
