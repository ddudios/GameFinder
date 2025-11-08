//
//  BaseViewController.swift
//  GameFinder
//
//  Created by Suji Jang on 9/27/25.
//

import UIKit

class BaseViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        configureHierarchy()
        configureLayout()
        configureView()
    }

    func configureHierarchy() { }
    func configureLayout() { }
    func configureView() {
        view.backgroundColor = .systemBackground
    }

    deinit {
        print("deinit: \(String(describing: type(of: self)))")
    }
    
    //MARK: - Alert
    func showAlert(title: String, message: String?) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: L10n.Alert.okButton, style: .default))
        present(alert, animated: true)
    }

    // MARK: - Notification Helper
    func handleNotificationToggle(for game: Game) {
        let isCurrentlyEnabled = NotificationManager.shared.isNotificationEnabled(gameId: game.id)

        if isCurrentlyEnabled {
            // 알림 제거
            let success = NotificationManager.shared.removeNotification(gameId: game.id)
            if success {
                let message = String(format: L10n.Notification.removed, game.name)
                showToast(message: message)
            }
        } else {
            // 출시일 확인
            if let releasedString = game.released,
               let releaseDate = dateFromString(releasedString) {
                let today = Calendar.current.startOfDay(for: Date())
                let release = Calendar.current.startOfDay(for: releaseDate)

                // 출시일이 오늘 또는 과거인 경우
                if release <= today {
                    showToast(message: L10n.Notification.discountComingSoon)
                    return
                }
            }

            // 알림 추가 - 시스템 알림 권한과 앱 내 알림 설정 모두 확인
            NotificationManager.shared.checkPermissionStatus { [weak self] isAuthorized in
                guard let self = self else { return }

                if !isAuthorized {
                    // 시스템 알림 권한이 없음
                    self.showSystemNotificationPermissionAlert()
                } else if !UserDefaults.isGlobalNotificationEnabled {
                    // 앱 내 전역 알림이 꺼져있음
                    self.showTurnOnNotificationAlert(for: game)
                } else {
                    // 모두 허용된 상태 - 알림 추가
                    self.addNotification(for: game)
                }
            }
        }
    }

    private func dateFromString(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.date(from: dateString)
    }

    private func showSystemNotificationPermissionAlert() {
        let alert = UIAlertController(
            title: L10n.Settings.appNotiTitle,
            message: L10n.Settings.appNotiMessage,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: L10n.Settings.appNotiSettingButton, style: .default) { _ in
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsUrl)
            }
        })

        alert.addAction(UIAlertAction(title: L10n.cancel, style: .cancel))
        present(alert, animated: true)
    }

    private func showTurnOnNotificationAlert(for game: Game) {
        let alert = UIAlertController(
            title: L10n.Notification.turnOnTitle,
            message: L10n.Notification.turnOnMessage,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: L10n.Notification.turnOnButton, style: .default) { [weak self] _ in
            // 전역 알림 켜기
            NotificationManager.shared.toggleGlobalNotification(enabled: true)
            // 게임 알림 추가
            self?.addNotification(for: game)
        })

        alert.addAction(UIAlertAction(title: L10n.Alert.okButton, style: .cancel))

        present(alert, animated: true)
    }

    private func addNotification(for game: Game) {
        let success = NotificationManager.shared.addNotification(game)
        if success {
            let alert = UIAlertController(
                title: nil,
                message: L10n.Notification.added,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: L10n.Alert.okButton, style: .default))
            present(alert, animated: true)
        }
    }
}
