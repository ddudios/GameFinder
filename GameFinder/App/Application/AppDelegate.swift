//
//  AppDelegate.swift
//  GameFinder
//
//  Created by Suji Jang on 9/27/25.
//

import UIKit
import RealmSwift

@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Realm 마이그레이션 설정
        configureRealm()

        NavigationBar.configureAppearance()

        return true
    }

    // MARK: - Realm Configuration
    private func configureRealm() {
        let config = Realm.Configuration(
            schemaVersion: 2, // 스키마 버전 증가
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < 2 {
                    // FavoriteGame, NotificationGame -> RealmGame 마이그레이션
                    // 기존 테이블은 자동으로 삭제되고 새 RealmGame 테이블 사용
                }
            },
            deleteRealmIfMigrationNeeded: true // 개발 중에는 마이그레이션 실패 시 DB 삭제
        )

        Realm.Configuration.defaultConfiguration = config

        // Realm 초기화 확인
        do {
            let realm = try Realm()
            print("✅ Realm initialized successfully at: \(realm.configuration.fileURL?.absoluteString ?? "")")
        } catch {
            print("❌ Realm initialization failed: \(error)")
        }
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

