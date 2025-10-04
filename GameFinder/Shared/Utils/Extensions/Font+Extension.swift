//
//  Font+Extension.swift
//  GameFinder
//
//  Created by Suji Jang on 9/30/25.
//

import UIKit

enum CustomFont: String {
    case chosun = "ChosunGu"
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
    /// SectionHeader
    struct Chosun {
        private init() { }
        static let bold18 = CustomFont.chosun.of(size: 18, weight: .bold)
        static let regular16 = CustomFont.chosun.of(size: 16)
    }
    
    /// Number
    enum NanumBarunGothic {
        static let bold12 = CustomFont.nanumBarunGothic.of(size: 12, weight: .bold)
    }
    
    /// Italic
    enum IlsangItalic {
        static let regular12 = CustomFont.IlsangItalic.of(size: 12)
    }
    
    struct Heading {
        private init() { }
        static let bold18 = UIFont.systemFont(ofSize: 18, weight: .bold)
        static let bold16 = UIFont.systemFont(ofSize: 16, weight: .bold)
    }
    
    struct Title {
        private init() { }
        static let semibold14 = UIFont.systemFont(ofSize: 14, weight: .semibold)
    }
    
    struct Body {
        private init() { }
        static let regular12 = UIFont.systemFont(ofSize: 12, weight: .regular)
    }
    
    struct Prominent {
        private init() { }
        static let bold15 = UIFont.systemFont(ofSize: 15, weight: .bold)
        static let semibold14 = UIFont.systemFont(ofSize: 14, weight: .semibold)
        static let semibold12 = UIFont.systemFont(ofSize: 12, weight: .semibold)
    }
        
    struct Label {
        private init() { }
        static let medium10 = UIFont.systemFont(ofSize: 10, weight: .medium)
    }
    
    struct Highlight {
        private init() { }
        static let heavy15 = UIFont.systemFont(ofSize: 15, weight: .heavy)
        static let heavy14 = UIFont.systemFont(ofSize: 14, weight: .heavy)
    }
}
