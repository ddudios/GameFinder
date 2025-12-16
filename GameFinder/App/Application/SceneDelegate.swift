//
//  SceneDelegate.swift
//  GameFinder
//
//  Created by Suji Jang on 9/27/25.
//

import UIKit
import UserNotifications

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: scene)

        let initialViewController = AppTabBarController()

        window?.rootViewController = initialViewController
        window?.makeKeyAndVisible()

        // 앱이 처음 실행될 때 위젯에서 딥링크로 열렸는지 확인
        if let urlContext = connectionOptions.urlContexts.first {
            let url = urlContext.url

            // gamefinder://game/{gameId} 형식 처리
            if url.scheme == "gamefinder",
               url.host == "game",
               let gameId = url.pathComponents.dropFirst().first,
               let id = Int(gameId) {
                // UI가 완전히 로드된 후 딥링크 처리
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.handleGameDeepLink(gameId: id)
                }
            }
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.

        // 앱이 active 될 때 뱃지와 알림 제거 (보험)
        UIApplication.shared.applicationIconBadgeNumber = 0
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.

        // 앱이 포그라운드로 진입할 때 뱃지와 알림 즉시 제거
        UIApplication.shared.applicationIconBadgeNumber = 0
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.

        // 백그라운드 진입 시 pending notifications의 badge를 1부터 재계산
        // (foreground에서 받은 알림이 제거되었으므로)
        NotificationManager.shared.updatePendingNotificationBadges()
    }

    // MARK: - Deep Link Handling
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }

        // gamefinder://game/{gameId} 형식 처리
        if url.scheme == "gamefinder",
           url.host == "game",
           let gameId = url.pathComponents.dropFirst().first,
           let id = Int(gameId) {
            handleGameDeepLink(gameId: id)
        }
    }

    private func handleGameDeepLink(gameId: Int) {
        guard let tabBarController = window?.rootViewController as? AppTabBarController,
              let navigationController = tabBarController.selectedViewController as? UINavigationController else {
            return
        }

        // GameDetailViewController로 이동
        let gameDetailViewModel = GameDetailViewModel(gameId: gameId)
        let gameDetailViewController = GameDetailViewController(viewModel: gameDetailViewModel)
        navigationController.pushViewController(gameDetailViewController, animated: true)

        // TabBar를 홈으로 전환 (필요한 경우)
        tabBarController.selectedIndex = 0
    }

}

