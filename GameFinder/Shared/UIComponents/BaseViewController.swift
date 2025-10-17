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
            // 알림 추가
            // 전역 알림이 꺼져있는지 확인
            if !UserDefaults.isGlobalNotificationEnabled {
                showTurnOnNotificationAlert(for: game)
            } else {
                addNotification(for: game)
            }
        }
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
