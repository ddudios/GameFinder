//
//  AppDelegate.swift
//  GameFinder
//
//  Created by Suji Jang on 9/27/25.
//

import UIKit
import FirebaseCore
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        FirebaseApp.configure()
        NavigationBar.configureAppearance()

        // 알림 권한 요청
        UNUserNotificationCenter.current().delegate = self

        return true
    }
    
    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    // 포그라운드에서 알림 표시
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }

    // 알림 탭 시 처리
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        if let gameId = userInfo["gameId"] as? Int {
            LogManager.userAction.info("🔔 User tapped notification for game: \(gameId)")
            navigateToGameDetail(gameId: gameId)
        }
        completionHandler()
    }

    // MARK: - Navigation Helper
    private func navigateToGameDetail(gameId: Int) {
        // SceneDelegate를 통해 window에 접근
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let sceneDelegate = windowScene.delegate as? SceneDelegate,
              let window = sceneDelegate.window,
              let tabBarController = window.rootViewController as? AppTabBarController else {
            LogManager.error.error("Failed to access TabBarController")
            return
        }

        // 첫 번째 탭(Finder)으로 전환
        tabBarController.selectedIndex = 0

        // 첫 번째 탭의 NavigationController 가져오기
        guard let navigationController = tabBarController.viewControllers?.first as? UINavigationController else {
            LogManager.error.error("Failed to access NavigationController")
            return
        }

        // 게임 상세 화면으로 이동
        let viewModel = GameDetailViewModel(gameId: gameId)
        let detailViewController = GameDetailViewController(viewModel: viewModel)

        // 현재 스택의 최상단 뷰컨트롤러가 이미 GameDetailViewController인 경우 스택 정리
        if let presentedVC = navigationController.topViewController?.presentedViewController {
            presentedVC.dismiss(animated: false)
        }

        // 게임 상세 화면으로 push
        navigationController.pushViewController(detailViewController, animated: true)

        LogManager.userAction.info("✅ Navigated to game detail: \(gameId)")
    }
}


