//
//  ActionButtonsCollectionViewCell.swift
//  GameFinder
//
//  Created by Suji Jang on 10/6/25.
//

import UIKit
import SnapKit
import RxSwift

final class ActionButtonsCollectionViewCell: BaseCollectionViewCell {

    let bookmarkButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(systemName: "bookmark"), for: .normal)
        button.setImage(UIImage(systemName: "bookmark.fill"), for: .selected)
        button.tintColor = .Signature
        button.backgroundColor = .clear
        return button
    }()

    let favoriteButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(systemName: "heart"), for: .normal)
        button.setImage(UIImage(systemName: "heart.fill"), for: .selected)
        button.tintColor = .systemRed
        button.backgroundColor = .clear
        return button
    }()

    let notificationButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(systemName: "bell"), for: .normal)
        button.setImage(UIImage(systemName: "bell.fill"), for: .selected)
        button.tintColor = .systemOrange
        button.backgroundColor = .clear
        return button
    }()

    private lazy var buttonStackView = {
        let stackView = UIStackView(arrangedSubviews: [bookmarkButton, favoriteButton, notificationButton])
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 24
        return stackView
    }()

    var onBookmarkButtonTapped: ((Int) -> Void)?
    var onFavoriteButtonTapped: ((Int) -> Void)?
    var onNotificationButtonTapped: ((Int) -> Void)?
    private var currentGameId: Int?
    private var disposeBag = DisposeBag()

    override func configureHierarchy() {
        contentView.addSubview(buttonStackView)

        bookmarkButton.addTarget(self, action: #selector(bookmarkButtonTapped), for: .touchUpInside)
        favoriteButton.addTarget(self, action: #selector(favoriteButtonTapped), for: .touchUpInside)
        notificationButton.addTarget(self, action: #selector(notificationButtonTapped), for: .touchUpInside)
    }

    override func configureLayout() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        buttonStackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.top.bottom.equalToSuperview().inset(8)
            make.width.equalTo(180) // 3개 버튼 + spacing
        }

        bookmarkButton.snp.makeConstraints { make in
            make.size.equalTo(44)
        }

        favoriteButton.snp.makeConstraints { make in
            make.size.equalTo(44)
        }

        notificationButton.snp.makeConstraints { make in
            make.size.equalTo(44)
        }
    }

    func configure(with gameId: Int, showsNotificationButton: Bool) {
        currentGameId = gameId
        notificationButton.isHidden = !showsNotificationButton

        // 버튼 상태 설정
        bookmarkButton.isSelected = ReadingManager.shared.isReading(gameId: gameId)
        favoriteButton.isSelected = FavoriteManager.shared.isFavorite(gameId: gameId)
        notificationButton.isSelected = showsNotificationButton
            ? NotificationManager.shared.isNotificationEnabled(gameId: gameId)
            : false

        // 실시간 동기화: 게임 기록 상태 변경 구독
        ReadingManager.shared.readingStatusChanged
            .filter { [weak self] (id, _) in id == self?.currentGameId }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_, isReading) in
                self?.bookmarkButton.isSelected = isReading
            })
            .disposed(by: disposeBag)

        // 실시간 동기화: 좋아요 상태 변경 구독
        FavoriteManager.shared.favoriteStatusChanged
            .filter { [weak self] (id, _) in id == self?.currentGameId }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_, isFavorite) in
                self?.favoriteButton.isSelected = isFavorite
            })
            .disposed(by: disposeBag)

        // 실시간 동기화: 알림 상태 변경 구독
        if showsNotificationButton {
            NotificationManager.shared.notificationStatusChanged
                .filter { [weak self] (id, _) in id == self?.currentGameId }
                .observe(on: MainScheduler.instance)
                .subscribe(onNext: { [weak self] (_, isEnabled) in
                    self?.notificationButton.isSelected = isEnabled
                })
                .disposed(by: disposeBag)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        notificationButton.isHidden = false
        disposeBag = DisposeBag()
    }

    // MARK: - Actions
    @objc private func bookmarkButtonTapped() {
        guard let gameId = currentGameId else { return }
        onBookmarkButtonTapped?(gameId)
    }

    @objc private func favoriteButtonTapped() {
        guard let gameId = currentGameId else { return }
        onFavoriteButtonTapped?(gameId)
    }

    @objc private func notificationButtonTapped() {
        guard let gameId = currentGameId else { return }
        onNotificationButtonTapped?(gameId)
    }
}
