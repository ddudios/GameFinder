//
//  NavigationBar.swift
//  GameFinder
//
//  Created by Suji Jang on 9/29/25.
//

import UIKit

final class NavigationBar {
    static func configureAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .systemBackground
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]

        let buttonAppearance = UIBarButtonItemAppearance(style: .plain)
        buttonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.secondaryLabel]
        buttonAppearance.highlighted.titleTextAttributes = [.foregroundColor: UIColor.secondaryLabel]
        appearance.buttonAppearance = buttonAppearance

        // 스크롤 엣지 효과 없을 때
        UINavigationBar.appearance().standardAppearance = appearance

        // 스크롤 엣지 효과 있을 때
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
}
