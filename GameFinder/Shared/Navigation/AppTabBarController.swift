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
    case fourth

    var title: String {
        switch self {
        case .first: return L10n.TabBar.first
        case .second: return L10n.TabBar.second
        case .third: return L10n.TabBar.third
        case .fourth: return L10n.TabBar.fourth
        }
    }

    var image: String {
        switch self {
        case .first: return "gamecontroller"
        case .second: return "rectangle.stack"
        case .third: return "gearshape"
        case .fourth: return "calendar"
        }
    }

    func viewController() -> UIViewController {
        let viewController: UIViewController
        switch self {
        case .first: viewController = FinderViewController()
        case .second: viewController = LibraryViewController()
        case .third: viewController = SettingViewController()
        case .fourth: viewController = CalendarViewController()
        }
        return UINavigationController(rootViewController: viewController)
    }
}

final class AppTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTabBarController()
        configureTabBarAppearance()

        // CRITICAL FIX: 위젯 데이터 강제 저장
        // 앱이 로드되자마자 Mock 데이터를 App Group에 저장
        testWidgetDataSaving()
    }

    /// 긴급 수정: 위젯 데이터 저장 테스트
    /// 이 메서드가 호출되면 반드시 App Group에 데이터가 저장됨
    private func testWidgetDataSaving() {
        // Mock 데이터로 테스트
        WidgetDataService.shared.testAppGroupWithMockData()

        // 0.5초 후 실제 API 데이터로 업데이트
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            await WidgetDataService.shared.updateWidgetData()
        }
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
        tabBarAppearance.backgroundColor = .systemBackground
        
        tabBarAppearance.stackedLayoutAppearance.selected.iconColor = UIColor.Signature
        tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.Signature]
        
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
