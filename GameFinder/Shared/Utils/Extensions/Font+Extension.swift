//
//  Font+Extension.swift
//  GameFinder
//
//  Created by Suji Jang on 9/30/25.
//

import UIKit

enum CustomFont: String {
    case nanumBarunGothic = "NanumBarunGothicOTF"
    case IlsangItalic = "87MMILSANG-Oblique"
    
    enum Weight: String {
        case ultraLight = "UltraLight"
        case light = "Light"
        case regular = ""
        case medium = "Medium"
        case semibold = "Semibold"
        case bold = "Bold"
    }
    
    func of(size: CGFloat, weight: Weight = .regular) -> UIFont? {
        let fontName = self.rawValue + weight.rawValue
        return UIFont(name: fontName, size: size) ?? UIFont.systemFont(ofSize: 40, weight: .bold)
    }
    
    static func debugPrintInstalledFonts() {
        UIFont.familyNames.sorted().forEach { family in
            let names = UIFont.fontNames(forFamilyName: family)
            if !names.isEmpty {
                print("Family: \(family)")
                names.forEach { print("  - \($0)") }  // 이 문자열이 PostScript 이름
            }
        }
    }
}

extension UIFont {
    /// Number
    enum NanumBarunGothic {
        static let bold16 = CustomFont.nanumBarunGothic.of(size: 16, weight: .bold)
        static let bold12 = CustomFont.nanumBarunGothic.of(size: 12, weight: .bold)
        
        static let regular12 = CustomFont.nanumBarunGothic.of(size: 12)
    }
    
    /// Italic
    enum IlsangItalic {
        static let regular12 = CustomFont.IlsangItalic.of(size: 12)
    }

    struct Heading {
        private init() { }
        static let heavy24 = UIFont.systemFont(ofSize: 24, weight: .heavy)
        static let heavy15 = UIFont.systemFont(ofSize: 15, weight: .heavy)
    }
    
    struct Title {
        private init() { }
        static let bold24 = UIFont.systemFont(ofSize: 24, weight: .bold)
        static let bold20 = UIFont.systemFont(ofSize: 20, weight: .bold)
        static let bold16 = UIFont.systemFont(ofSize: 16, weight: .bold)
        static let bold14 = UIFont.systemFont(ofSize: 14, weight: .bold)
    }
    
    struct Body {
        private init() { }
        static let regular16 = UIFont.systemFont(ofSize: 16, weight: .regular)
        
        static let semibold14 = UIFont.systemFont(ofSize: 14, weight: .semibold)
        static let regular14 = UIFont.systemFont(ofSize: 14, weight: .regular)
        
        static let bold12 = UIFont.systemFont(ofSize: 12, weight: .bold)
        static let regular12 = UIFont.systemFont(ofSize: 12, weight: .regular)
    }
}
