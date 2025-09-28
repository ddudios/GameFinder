//
//  PointColor.swift
//  GameFinder
//
//  Created by Suji Jang on 9/29/25.
//

import UIKit

enum GamePadGlass {
    static let a = UIColor(red: 0/255,   green: 220/255, blue: 130/255, alpha: 1.0)
    static let b = UIColor(red: 255/255, green: 80/255,  blue: 100/255, alpha: 1.0)
    static let x = UIColor(red: 50/255,  green: 130/255, blue: 255/255, alpha: 1.0)
    static let y = UIColor(red: 255/255, green: 210/255, blue: 70/255,  alpha: 1.0)

    // 유리(글래스) 배경 위에 얹을 반투명 레이어 (빛번짐 느낌)
    // 라이트: 하이라이트 계열, 다크: 살짝 더 어두운 막으로 대비 확보
    static var glassOverlayLight: UIColor { UIColor(white: 1.0, alpha: 0.18) }
    static var glassOverlayDark:  UIColor { UIColor(white: 0.0, alpha: 0.20) }

    // 버튼 상태 색 (기본/눌림/비활성)
    static func fill(_ base: UIColor) -> (normal: UIColor, pressed: UIColor, disabled: UIColor) {
        (
            normal: base.withAlphaComponent(0.95),
            pressed: base.withAlphaComponent(0.75),
            disabled: base.withAlphaComponent(0.35)
        )
    }

    // 유리 테두리 느낌
    static let strokeLight = UIColor(white: 1.0, alpha: 0.30)
    static let strokeDark  = UIColor(white: 1.0, alpha: 0.16)
}
