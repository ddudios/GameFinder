//
//  SettingViewController.swift
//  GameFinder
//
//  Created by Suji Jang on 9/29/25.
//

import UIKit
import SnapKit

enum SettingSection: Int, CaseIterable {
    case general
    case support

    var title: String {
        switch self {
        case .general:
            return "General"
        case .support:
            return "Support"
        }
    }
}

enum SettingItem {
    case notification
    case language
    case contact

    var title: String {
        switch self {
        case .notification:
            return "Notifications"
        case .language:
            return "Language"
        case .contact:
            return "Contact"
        }
    }

    var icon: String {
        switch self {
        case .notification:
            return "bell.fill"
        case .language:
            return "globe"
        case .contact:
            return "envelope"
        }
    }
}

final class SettingViewController: BaseViewController {

    // MARK: - Properties
    private let sections: [[SettingItem]] = [
        [.notification, .language],      // General
        [.contact]                        // Support
    ]

    // MARK: - UI Components
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .systemBackground
        tableView.register(SettingTableViewCell.self, forCellReuseIdentifier: SettingTableViewCell.identifier)
        return tableView
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    private func setNavigationBar() {
        navigationItem.title = L10n.Settings.navTitle
    }

    override func configureHierarchy() {
        view.addSubview(tableView)
    }

    override func configureLayout() {
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }

    override func configureView() {
        super.configureView()
        setNavigationBar()
    }

    // MARK: - Actions
    private func showNotificationSettings() {
        NotificationManager.shared.checkPermissionStatus { [weak self] isAuthorized in
            guard let self = self else { return }

            if isAuthorized {
                // 권한이 있으면 토글 설정 표시
                self.showNotificationToggle()
            } else {
                // 권한이 없으면 권한 요청
                self.requestNotificationPermission()
            }
        }
    }

    private func requestNotificationPermission() {
        NotificationManager.shared.requestPermission { [weak self] granted in
            if granted {
                self?.showNotificationToggle()
            } else {
                self?.showPermissionDeniedAlert()
            }
        }
    }

    private func showNotificationToggle() {
        let isEnabled = UserDefaults.isGlobalNotificationEnabled

        let alert = UIAlertController(
            title: "Notifications",
            message: "Enable notifications to receive alerts for game releases.",
            preferredStyle: .actionSheet
        )

        let toggleTitle = isEnabled ? "Turn Off Notifications" : "Turn On Notifications"
        let toggleStyle: UIAlertAction.Style = isEnabled ? .destructive : .default

        alert.addAction(UIAlertAction(title: toggleTitle, style: toggleStyle) { [weak self] _ in
            let newState = !isEnabled
            NotificationManager.shared.toggleGlobalNotification(enabled: newState)

            let message = newState ? "Notifications enabled" : "Notifications disabled"
            let confirmAlert = UIAlertController(
                title: nil,
                message: message,
                preferredStyle: .alert
            )
            confirmAlert.addAction(UIAlertAction(title: "OK", style: .default))
            self?.present(confirmAlert, animated: true)
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = view
            popoverController.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }

        present(alert, animated: true)
    }

    private func showPermissionDeniedAlert() {
        let alert = UIAlertController(
            title: "Permission Required",
            message: "Please enable notifications in Settings to receive game release alerts.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsUrl)
            }
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func showLanguageSelection() {
        let alert = UIAlertController(
            title: "Select Language",
            message: "Choose your preferred language",
            preferredStyle: .actionSheet
        )

        // 한국어
        alert.addAction(UIAlertAction(title: "한국어", style: .default) { [weak self] _ in
            self?.changeLanguage(to: "ko")
        })

        // English
        alert.addAction(UIAlertAction(title: "English", style: .default) { [weak self] _ in
            self?.changeLanguage(to: "en")
        })

        // 日本語
        alert.addAction(UIAlertAction(title: "日本語", style: .default) { [weak self] _ in
            self?.changeLanguage(to: "ja")
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = view
            popoverController.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }

        present(alert, animated: true)
    }

    private func changeLanguage(to languageCode: String) {
        UserDefaults.standard.set([languageCode], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()

        let alert = UIAlertController(
            title: L10n.Alert.languageTitle,
            message: L10n.Alert.languageMessage,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: L10n.Alert.okButton, style: .default))
        present(alert, animated: true)
    }

    private func copyEmailToClipboard() {
        let email = "jddudios@gmail.com"
        UIPasteboard.general.string = email

        let alert = UIAlertController(
            title: nil,
            message: "문의 이메일 주소가 복사되었습니다.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension SettingViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: SettingTableViewCell.identifier,
            for: indexPath
        ) as? SettingTableViewCell else {
            return UITableViewCell()
        }

        let item = sections[indexPath.section][indexPath.row]
        cell.configure(with: item)
        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return SettingSection(rawValue: section)?.title
    }
}

// MARK: - UITableViewDelegate
extension SettingViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let item = sections[indexPath.section][indexPath.row]

        switch item {
        case .notification:
            showNotificationSettings()
        case .language:
            showLanguageSelection()
        case .contact:
            copyEmailToClipboard()
        }
    }
}

// MARK: - SettingTableViewCell
final class SettingTableViewCell: UITableViewCell {
    static let identifier = "SettingTableViewCell"

    private let iconImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .Signature
        return imageView
    }()

    private let titleLabel = {
        let label = UILabel()
        label.font = .Body.regular16
        label.textColor = .label
        return label
    }()

    private let chevronImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "chevron.right")
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .secondaryLabel
        return imageView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(chevronImageView)

        iconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(24)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
        }

        chevronImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(20)
        }
    }

    func configure(with item: SettingItem) {
        titleLabel.text = item.title
        iconImageView.image = UIImage(systemName: item.icon)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        iconImageView.image = nil
    }
}
