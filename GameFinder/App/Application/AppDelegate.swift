//
//  AppDelegate.swift
//  GameFinder
//
//  Created by Suji Jang on 9/27/25.
//

import UIKit
import UserNotifications
import FirebaseCore
import FirebaseMessaging  // Push 관련

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        NavigationBar.configureAppearance()

        // Firebase 초기화
        FirebaseApp.configure()

        // 알림 권한 요청 (로컬, 원격)
        if #available(iOS 10.0, *) {
            // iOS 10 이상일 때 (UserNotifications.framework 사용)
            UNUserNotificationCenter.current().delegate = self

            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: { _, _ in }
            )
        } else {
            // iOS 9 이하 (UIUserNotificationSettings 사용)
            let settings: UIUserNotificationSettings = UIUserNotificationSettings(
                types: [.alert, .badge, .sound],
                categories: nil
            )
            application.registerUserNotificationSettings(settings)
        }

        application.registerForRemoteNotifications()

        // 메시지 대리자 설정: Firebase가 APNs 대신에 Message를 보낼 수 있도록 설정
        Messaging.messaging().delegate = self

        // Foreground에도 Push 표시
        UIViewController.swizzleMethod()
        
        return true
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // 앱이 포그라운드로 진입할 때 뱃지와 알림 즉시 제거
        application.applicationIconBadgeNumber = 0
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // 앱이 active 될 때 뱃지와 알림 제거 (보험)
        application.applicationIconBadgeNumber = 0
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
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
        // 포그라운드에서는 뱃지를 표시하지 않음 (배너와 사운드만)
        completionHandler([.banner, .sound])
        
        updateBadgeCount()
    }

    // 알림 탭 시 처리
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo

        // 알림을 탭하면 앱이 열리므로 뱃지와 알림 제거는 willEnterForeground에서 처리됨

        if let gameId = userInfo["gameId"] as? Int {
            LogManager.userAction.info("User tapped notification for game: \(gameId)")
            navigateToGameDetail(gameId: gameId)
        }
        updateBadgeCount()
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

        LogManager.userAction.info("Navigated to game detail: \(gameId)")
    }
    
    // Remote
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {

        // 1. APNs 토큰 등록: APNs에서 발급한 디바이스 토큰 정보
        Messaging.messaging().apnsToken = deviceToken

        // 2. 이제 FCM 토큰 요청: 현재 등록된 토큰 가져오기 (필요한 곳에 직접 작성)
        Messaging.messaging().token { token, error in
            if let error = error {
                print("Error fetching FCM registration token: \(error)")
            } else if let token = token {
                print("FCM registration token: \(token)")
            }
        }
    }
    
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {

        // 백그라운드 상태에서도 푸시 수신 시 실행됨
        updateBadgeCount()
        completionHandler(.newData)
    }

    private func updateBadgeCount() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
                let count = notifications.count
                DispatchQueue.main.async {
                    // iOS가 서버의 badge를 덮어쓰지 않게 하기 위해 payload에서 "badge" 제거 필요
                    UIApplication.shared.applicationIconBadgeNumber = count
                }
            }
        }
    }
}

//MARK: - MessagingDelegate (Remote)
extension AppDelegate: MessagingDelegate {
    
    // 토큰 갱신 모니터링: 디바이스 토큰 정보가 변경되면 알려줌
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
      print("Firebase registration token: \(String(describing: fcmToken))")

      let dataDict: [String: String] = ["token": fcmToken ?? ""]
      NotificationCenter.default.post(
        name: Notification.Name("FCMToken"),
        object: nil,
        userInfo: dataDict
      )
    }
}
