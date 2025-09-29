//
//  String+Extension.swift
//  GameFinder
//
//  Created by Suji Jang on 9/30/25.
//

import Foundation

extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "fail: localize")
    }
    
    func localized(with: String, number: Int) -> String {
        return String(format: self.localized, with, number)
    }
}
