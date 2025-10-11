//
//  UserDefaults+Extension.swift
//  GameFinder
//
//  Created by Suji Jang on 10/11/25.
//

import Foundation

extension UserDefaults {
    private enum Keys {
        static let isGlobalNotificationEnabled = "isGlobalNotificationEnabled"
    }

    static var isGlobalNotificationEnabled: Bool {
        get {
            return standard.bool(forKey: Keys.isGlobalNotificationEnabled)
        }
        set {
            standard.set(newValue, forKey: Keys.isGlobalNotificationEnabled)
        }
    }
}
