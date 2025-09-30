//
//  AppColor.swift
//  GameFinder
//
//  Created by Suji Jang on 9/29/25.
//

import UIKit

public enum AppColor {
    case system, light, dark, glassLight, glassDark
    public static var selected: AppColor = .system

    public func palette(for trait: UITraitCollection) -> AppPalette {
        switch self {
        case .light: return AppPalette(
            background: UIColor(red: 252/255, green: 252/255, blue: 252/255, alpha: 1),  // white
            textPrimary: UIColor(white: 0.11, alpha: 0.88),
            textSecondary: UIColor(white: 0.35, alpha: 0.62),
            separator: UIColor(white: 0.0, alpha: 0.08),
            glassBackground: UIColor(white: 1.0, alpha: 0.25),
            glassBorder: UIColor(white: 1.0, alpha: 0.30)
        )
        case .dark: return AppPalette(
            background: UIColor(red: 10/255, green: 10/255, blue: 12/255, alpha: 1),
            textPrimary: UIColor(white: 0.92, alpha: 0.92),
            textSecondary: UIColor(white: 0.78, alpha: 0.65),
            separator: UIColor(white: 1.0, alpha: 0.08),
            glassBackground: UIColor(red: 18/255, green: 18/255, blue: 18/255, alpha: 0.35),
            glassBorder: UIColor(white: 1.0, alpha: 0.16)
        )
        case .glassLight: return AppPalette(
            background: UIColor(white: 1.0, alpha: 0.25),
            textPrimary: UIColor(white: 0.11, alpha: 0.9),
            textSecondary: UIColor(white: 0.35, alpha: 0.62),
            separator: UIColor(white: 0.0, alpha: 0.08),
            glassBackground: UIColor(white: 1.0, alpha: 0.25),
            glassBorder: UIColor(white: 1.0, alpha: 0.30)
        )
        case .glassDark: return AppPalette(
            background: UIColor(red: 18/255, green: 18/255, blue: 18/255, alpha: 0.35),
            textPrimary: UIColor(white: 0.92, alpha: 0.92),
            textSecondary: UIColor(white: 0.78, alpha: 0.65),
            separator: UIColor(white: 1.0, alpha: 0.08),
            glassBackground: UIColor(red: 18/255, green: 18/255, blue: 18/255, alpha: 0.35),
            glassBorder: UIColor(white: 1.0, alpha: 0.16)
        )
        case .system:
            return (trait.userInterfaceStyle == .dark)
            ? AppColor.dark.palette(for: trait)
            : AppColor.light.palette(for: trait)
        }
    }
}

public struct AppPalette {
    public let background: UIColor
    public let textPrimary: UIColor
    public let textSecondary: UIColor
    public let separator: UIColor
    public let glassBackground: UIColor
    public let glassBorder: UIColor
}
