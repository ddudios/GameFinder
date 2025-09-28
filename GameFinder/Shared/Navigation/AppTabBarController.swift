//
//  AppTabBarController.swift
//  GameFinder
//
//  Created by Suji Jang on 9/29/25.
//

import UIKit

enum TabBarItem: Int, CaseIterable {
    case first
    case second
    case third
    
    var title: String {
        switch self {
        case .first: return "Finder"
        case .second: return "Library"
        case .third: return "Settings"
        }
    }
    
    var image: String {
        switch self {
        case .first: return "gamecontroller"
        case .second: return "rectangle.stack"
        case .third: return "gearshape"
        }
    }
    
    func viewController() -> UIViewController {
        let viewController: UIViewController
        switch self {
        case .first: viewController = FinderViewController()
        case .second: viewController = LibraryViewController()
        case .third: viewController = SettingViewController()
        }
        return UINavigationController(rootViewController: viewController)
    }
}

final class AppTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTabBarController()
        configureTabBarAppearance()
    }
    
    private func configureTabBarController() {
        let viewControllers = TabBarItem.allCases.map { tab -> UIViewController in
            let vc = tab.viewController()
            vc.tabBarItem = UITabBarItem(title: tab.title,
                                         image: UIImage(systemName: tab.image),
                                         tag: tab.rawValue)
            return vc
        }
        self.viewControllers = viewControllers
    }
    
    private func configureTabBarAppearance() {
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = .clear
        
        tabBarAppearance.stackedLayoutAppearance.selected.iconColor = UIColor.label
        tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.label]
        
        tabBarAppearance.stackedLayoutAppearance.normal.iconColor = .quaternaryLabel
        tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.quaternaryLabel]
        
        // 스크롤 엣지 효과가 없을 때
        UITabBar.appearance().standardAppearance = tabBarAppearance
        
        // 스크롤 엣지 효과가 있을 때
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
    }
}
