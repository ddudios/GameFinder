//
//  SignitureColor.swift
//  GameFinder
//
//  Created by Suji Jang on 9/29/25.
//

import UIKit

enum Signature {
    // 메인 포인트
    static var main: UIColor {
        UIColor { tc in
            (tc.userInterfaceStyle == .dark) ? UIColor(red: 66/255, green: 235/255, blue: 208/255, alpha: 1.0) : UIColor(red: 26/255, green: 196/255, blue: 160/255, alpha: 1.0)
        }
    }

    // 보조 포인트
    static var secondary: UIColor {
        UIColor { tc in
            (tc.userInterfaceStyle == .dark) ? UIColor(red: 138/255, green: 92/255, blue: 255/255, alpha: 1.0) : UIColor(red: 116/255, green: 84/255, blue: 255/255, alpha: 1.0)
        }
    }
}
