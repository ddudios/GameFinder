//
//  GameListCollectionViewCell.swift
//  GameFinder
//
//  Created by Suji Jang on 10/4/25.
//

import UIKit
import SnapKit
import Kingfisher
import RxSwift

final class GameListCollectionViewCell: BaseCollectionViewCell {

    private let iconImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 12
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray5
        return imageView
    }()

    private let titleLabel = {
        let label = UILabel()
        label.font = .Title.bold16
        label.textColor = .label
        label.numberOfLines = 1
        return label
    }()

    private let genreLabel = {
        let label = UILabel()
        label.font = .IlsangItalic.regular12
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        return label
    }()

    private let ratingLabel = {
        let label = UILabel()
        label.font = .NanumBarunGothic.bold12
        label.textColor = .label
        return label
    }()

    private let starImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "star.fill")
        imageView.tintColor = .Signature
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let releaseBadgeView = {
        let view = UIView()
        view.backgroundColor = UIColor.Signature
        view.layer.cornerRadius = 12
        return view
    }()

    private let releaseBadgeLabel = {
        let label = UILabel()
        label.font = .Body.bold12
        label.textColor = .label
        label.textAlignment = .center
        return label
    }()

    private let calendarImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "calendar")
        imageView.tintColor = .secondaryLabel
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let releaseDateLabel = {
        let label = UILabel()
        label.font = .Body.regular12
        label.textColor = .secondaryLabel
        return label
    }()

    private lazy var releaseStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [releaseBadgeView, calendarImageView, releaseDateLabel])
        stackView.axis = .horizontal
        stackView.spacing = 4
        stackView.alignment = .center
        stackView.isHidden = true
        return stackView
    }()

    private let separatorView = {
        let view = UIView()
        view.backgroundColor = UIColor.label.withAlphaComponent(0.2)
        return view
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
        button.isHidden = true  // 기본은 숨김
        return button
    }()

    let bookmarkButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(systemName: "bookmark"), for: .normal)
        button.setImage(UIImage(systemName: "bookmark.fill"), for: .selected)
        button.tintColor = .Signature
        button.backgroundColor = .clear
        button.isHidden = true  // 기본은 숨김
        return button
    }()

    var onFavoriteButtonTapped: ((Int) -> Void)?
    var onNotificationButtonTapped: ((Int) -> Void)?
    var onBookmarkButtonTapped: ((Int) -> Void)?
    private var currentGameId: Int?
    private var disposeBag = DisposeBag()

    override func configureHierarchy() {
        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(genreLabel)
        contentView.addSubview(starImageView)
        contentView.addSubview(ratingLabel)
        contentView.addSubview(releaseStackView)
        releaseBadgeView.addSubview(releaseBadgeLabel)
        contentView.addSubview(separatorView)
        contentView.addSubview(favoriteButton)
        favoriteButton.addTarget(self, action: #selector(favoriteButtonTapped), for: .touchUpInside)
        contentView.addSubview(notificationButton)
        notificationButton.addTarget(self, action: #selector(notificationButtonTapped), for: .touchUpInside)
        contentView.addSubview(bookmarkButton)
        bookmarkButton.addTarget(self, action: #selector(bookmarkButtonTapped), for: .touchUpInside)
    }

    override func configureLayout() {
        iconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.size.equalTo(80)
        }

        bookmarkButton.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(12)
            make.trailing.equalTo(favoriteButton.snp.leading).offset(-4)
            make.size.equalTo(36)
        }

        favoriteButton.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(12)
            make.trailing.equalToSuperview().inset(8)
            make.size.equalTo(36)
        }

        notificationButton.snp.makeConstraints { make in
            make.centerY.equalTo(favoriteButton)
            make.trailing.equalToSuperview().inset(8)
            make.size.equalTo(36)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(16)
            make.top.equalToSuperview().inset(16)
            make.trailing.equalTo(bookmarkButton.snp.leading).offset(-8)
        }

        genreLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.trailing.equalTo(titleLabel)
        }

        starImageView.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.bottom.equalToSuperview().inset(16)
            make.size.equalTo(12)
        }

        ratingLabel.snp.makeConstraints { make in
            make.leading.equalTo(starImageView.snp.trailing).offset(4)
            make.centerY.equalTo(starImageView)
        }

        releaseStackView.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.bottom.equalToSuperview().inset(16)
        }

        releaseBadgeView.snp.makeConstraints { make in
            make.height.equalTo(24)
        }

        releaseBadgeLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
        }

        calendarImageView.snp.makeConstraints { make in
            make.size.equalTo(14)
        }

        separatorView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview()
            make.height.equalTo(1)
        }
    }

    override func configureView() {
        super.configureView()
        backgroundColor = .clear
    }

    func configure(with game: Game, isUpcoming: Bool = false, isReading: Bool = false, isFavoriteOnly: Bool = false) {
        currentGameId = game.id
        titleLabel.text = game.name

        if isFavoriteOnly {
            // Favorite Only: 좋아요 버튼만 표시 (오른쪽 중앙 정렬)
            favoriteButton.isHidden = false
            notificationButton.isHidden = true
            bookmarkButton.isHidden = true
            favoriteButton.isSelected = FavoriteManager.shared.isFavorite(gameId: game.id)

            // 좋아요 버튼을 오른쪽 중앙으로 재배치
            favoriteButton.snp.remakeConstraints { make in
                make.centerY.equalToSuperview()
                make.trailing.equalToSuperview().inset(8)
                make.size.equalTo(36)
            }

            // titleLabel trailing 제약 조정
            titleLabel.snp.remakeConstraints { make in
                make.leading.equalTo(iconImageView.snp.trailing).offset(16)
                make.top.equalToSuperview().inset(16)
                make.trailing.equalTo(favoriteButton.snp.leading).offset(-8)
            }

            // 실시간 동기화: 좋아요 상태 변경 구독
            FavoriteManager.shared.favoriteStatusChanged
                .filter { [weak self] (gameId, _) in
                    gameId == self?.currentGameId
                }
                .observe(on: MainScheduler.instance)
                .subscribe(onNext: { [weak self] (_, isFavorite) in
                    self?.favoriteButton.isSelected = isFavorite
                })
                .disposed(by: disposeBag)
        } else if isReading {
            // Reading 카테고리: 좋아요 버튼 숨김, 북마크 버튼만 표시 (오른쪽 중앙 정렬)
            favoriteButton.isHidden = true
            notificationButton.isHidden = true
            bookmarkButton.isHidden = false
            bookmarkButton.isSelected = ReadingManager.shared.isReading(gameId: game.id)

            // 북마크 버튼을 오른쪽 중앙으로 재배치
            bookmarkButton.snp.remakeConstraints { make in
                make.centerY.equalToSuperview()
                make.trailing.equalToSuperview().inset(8)
                make.size.equalTo(36)
            }

            // titleLabel trailing 제약 조정
            titleLabel.snp.remakeConstraints { make in
                make.leading.equalTo(iconImageView.snp.trailing).offset(16)
                make.top.equalToSuperview().inset(16)
                make.trailing.equalTo(bookmarkButton.snp.leading).offset(-8)
            }

            // 실시간 동기화: 게임 기록 상태 변경 구독
            ReadingManager.shared.readingStatusChanged
                .filter { [weak self] (gameId, _) in
                    gameId == self?.currentGameId
                }
                .observe(on: MainScheduler.instance)
                .subscribe(onNext: { [weak self] (_, isReading) in
                    self?.bookmarkButton.isSelected = isReading
                })
                .disposed(by: disposeBag)
        } else if isUpcoming {
            // upcomingGames: 좋아요 버튼 숨김, 알림 버튼만 표시 (중앙 정렬), 북마크 숨김
            favoriteButton.isHidden = true
            notificationButton.isHidden = false
            bookmarkButton.isHidden = true
            notificationButton.isSelected = NotificationManager.shared.isNotificationEnabled(gameId: game.id)

            // 알림 버튼을 오른쪽 중앙으로 재배치
            notificationButton.snp.remakeConstraints { make in
                make.centerY.equalToSuperview()
                make.trailing.equalToSuperview().inset(8)
                make.size.equalTo(36)
            }

            // titleLabel trailing 제약 조정
            titleLabel.snp.remakeConstraints { make in
                make.leading.equalTo(iconImageView.snp.trailing).offset(16)
                make.top.equalToSuperview().inset(16)
                make.trailing.equalTo(notificationButton.snp.leading).offset(-8)
            }

            // 실시간 동기화: 알림 상태 변경 구독
            NotificationManager.shared.notificationStatusChanged
                .filter { [weak self] (gameId, _) in
                    gameId == self?.currentGameId
                }
                .observe(on: MainScheduler.instance)
                .subscribe(onNext: { [weak self] (_, isEnabled) in
                    self?.notificationButton.isSelected = isEnabled
                })
                .disposed(by: disposeBag)
        } else {
            // 일반 게임: 좋아요 & 북마크 버튼 표시, 알림 버튼 숨김
            favoriteButton.isHidden = false
            notificationButton.isHidden = true
            bookmarkButton.isHidden = false
            favoriteButton.isSelected = FavoriteManager.shared.isFavorite(gameId: game.id)
            bookmarkButton.isSelected = ReadingManager.shared.isReading(gameId: game.id)

            // 원래 레이아웃으로 복원
            bookmarkButton.snp.remakeConstraints { make in
                make.top.equalToSuperview().inset(12)
                make.trailing.equalTo(favoriteButton.snp.leading).offset(-4)
                make.size.equalTo(36)
            }

            favoriteButton.snp.remakeConstraints { make in
                make.top.equalToSuperview().inset(12)
                make.trailing.equalToSuperview().inset(8)
                make.size.equalTo(36)
            }

            titleLabel.snp.remakeConstraints { make in
                make.leading.equalTo(iconImageView.snp.trailing).offset(16)
                make.top.equalToSuperview().inset(16)
                make.trailing.equalTo(bookmarkButton.snp.leading).offset(-8)
            }

            // 실시간 동기화: 좋아요 상태 변경 구독
            FavoriteManager.shared.favoriteStatusChanged
                .filter { [weak self] (gameId, _) in
                    gameId == self?.currentGameId
                }
                .observe(on: MainScheduler.instance)
                .subscribe(onNext: { [weak self] (_, isFavorite) in
                    self?.favoriteButton.isSelected = isFavorite
                })
                .disposed(by: disposeBag)

            // 실시간 동기화: 게임 기록 상태 변경 구독
            ReadingManager.shared.readingStatusChanged
                .filter { [weak self] (gameId, _) in
                    gameId == self?.currentGameId
                }
                .observe(on: MainScheduler.instance)
                .subscribe(onNext: { [weak self] (_, isReading) in
                    self?.bookmarkButton.isSelected = isReading
                })
                .disposed(by: disposeBag)
        }

        let genreNames = game.genres.map { $0.name }
        genreLabel.text = genreNames.prefix(2).joined(separator: " • ")

        if isUpcoming {
            // COMING SOON 섹션: 출시일 표시
            starImageView.isHidden = true
            ratingLabel.isHidden = true
            releaseStackView.isHidden = false

            if let releaseDate = game.released {
                releaseDateLabel.text = releaseDate

                // 오늘/내일 체크
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"

                if let date = dateFormatter.date(from: releaseDate) {
                    let calendar = Calendar.current
                    let today = calendar.startOfDay(for: Date())
                    let releaseDay = calendar.startOfDay(for: date)

                    if let dayDifference = calendar.dateComponents([.day], from: today, to: releaseDay).day {
                        if dayDifference == 0 {
                            releaseBadgeLabel.text = L10n.today
                            releaseBadgeView.isHidden = false
                        } else if dayDifference == 1 {
                            releaseBadgeLabel.text = L10n.tomorrow
                            releaseBadgeView.isHidden = false
                        } else {
                            releaseBadgeView.isHidden = true
                        }
                    } else {
                        releaseBadgeView.isHidden = true
                    }
                } else {
                    releaseBadgeView.isHidden = true
                }
            } else {
                releaseStackView.isHidden = true
                releaseBadgeView.isHidden = true
            }
        } else {
            // 일반 섹션: 평점 표시
            starImageView.isHidden = false
            ratingLabel.isHidden = false
            ratingLabel.text = String(format: "%.1f", game.rating)

            releaseStackView.isHidden = true
            releaseBadgeView.isHidden = true
        }

        if let backgroundImageString = game.backgroundImage,
           let imageURL = URL(string: backgroundImageString) {
            iconImageView.showSkeletonLoading()
            iconImageView.kf.setImage(
                with: imageURL,
                placeholder: UIImage(named: "noImage_icon_black"),
                options: [
                    .transition(.fade(0.2)),
                    .cacheOriginalImage
                ],
                completionHandler: { [weak self] _ in
                    self?.iconImageView.hideSkeletonLoading()
                }
            )
        } else {
            iconImageView.image = UIImage(named: "noImage_icon_black")
            iconImageView.hideSkeletonLoading()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        iconImageView.kf.cancelDownloadTask()
        iconImageView.image = nil
        iconImageView.hideSkeletonLoading()
        titleLabel.text = nil
        genreLabel.text = nil
        ratingLabel.text = nil
        releaseDateLabel.text = nil
        releaseBadgeView.isHidden = true
        releaseStackView.isHidden = true
        starImageView.isHidden = false
        ratingLabel.isHidden = false
        favoriteButton.isHidden = false
        notificationButton.isHidden = true
        bookmarkButton.isHidden = true
        disposeBag = DisposeBag()
    }

    // MARK: - Actions
    @objc private func favoriteButtonTapped() {
        guard let gameId = currentGameId else { return }
        onFavoriteButtonTapped?(gameId)
    }

    @objc private func notificationButtonTapped() {
        guard let gameId = currentGameId else { return }
        onNotificationButtonTapped?(gameId)
    }

    @objc private func bookmarkButtonTapped() {
        guard let gameId = currentGameId else { return }
        onBookmarkButtonTapped?(gameId)
    }
}
