//
//  FeaturedGameCell.swift
//  GameFinder
//
//  Created by Suji Jang on 9/30/25.
//

import UIKit
import SnapKit
import Kingfisher
import RxSwift

final class CardCollectionViewCell: BaseCollectionViewCell {

    // MARK: - UI Components
    // 모든 컨텐츠를 담는 컨테이너 (transform은 여기에만 적용)
    let contentContainer = {
        let view = UIView()
        view.clipsToBounds = false
        return view
    }()

    private let imageContainerView = {
        let view = UIView()
        view.layer.cornerRadius = 28
        view.clipsToBounds = true
        view.backgroundColor = .clear
        return view
    }()

    let imageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .clear
        return imageView
    }()

    private let gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        // 하단 그라디에이션만 (상단은 완전 투명)
        layer.colors = [
            UIColor.clear.cgColor,
            UIColor.systemBackground.withAlphaComponent(0.6).cgColor
        ]
        layer.locations = [0.6, 1.0]
        layer.startPoint = CGPoint(x: 0.5, y: 0.0) // 상단 중앙
        layer.endPoint = CGPoint(x: 0.5, y: 1.0) // 하단 중앙
        return layer
    }()

    let badgeView = BadgeView()

    // 출시일 뷰 (upcoming games용)
    private let releaseDateBadge = {
        let view = UIView()
        view.backgroundColor = UIColor.systemBackground
        view.layer.cornerRadius = 16
        view.clipsToBounds = true
        view.isHidden = true
        return view
    }()

    private let releaseDateTextLabel = {
        let label = UILabel()
        label.font = .Chosun.regular16
        label.textColor = .label
        label.numberOfLines = 1
        label.textAlignment = .center
        return label
    }()

    // 타이틀 컨테이너 (셀 경계를 넘어가도록)
    private let titleContainer = {
        let view = UIView()
        view.clipsToBounds = false
        return view
    }()

    let floatingTitleLabel = {
        let label = UILabel()
        label.font = .Heading.heavy24
        label.adjustsFontForContentSizeCategory = true
        label.textColor = UIColor.label
        label.numberOfLines = 2
        label.layer.shadowColor = UIColor.systemBackground.cgColor
        label.layer.shadowOpacity = 0.8
        label.layer.shadowOffset = CGSize(width: 0, height: 2)
        label.layer.shadowRadius = 4
        label.alpha = 0 // 초기값 숨김 (visibility용)
        return label
    }()

    let subtitleLabel = {
        let label = UILabel()
        label.font = .IlsangItalic.regular12
        label.adjustsFontForContentSizeCategory = true
        label.textColor = UIColor.label
        label.numberOfLines = 1
        label.alpha = 0 // 초기값 숨김 (visibility용)
        return label
    }()

    private let loadingIndicator = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.color = .label
        return indicator
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
        button.tintColor = .systemBlue
        button.backgroundColor = .clear
        button.isHidden = true  // 기본은 숨김 (upcomingGames에서만 표시)
        return button
    }()

    let bookmarkButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(systemName: "bookmark"), for: .normal)
        button.setImage(UIImage(systemName: "bookmark.fill"), for: .selected)
        button.tintColor = .systemOrange
        button.backgroundColor = .clear
        button.isHidden = true  // 기본은 숨김 (upcomingGames에서만 표시)
        return button
    }()

    var onFavoriteButtonTapped: ((Int) -> Void)?
    var onNotificationButtonTapped: ((Int) -> Void)?
    var onBookmarkButtonTapped: ((Int) -> Void)?
    private var currentGameId: Int?
    private var disposeBag = DisposeBag()

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.kf.cancelDownloadTask()
        imageView.image = nil
        imageView.alpha = 1.0
        imageView.hideSkeleton()
        floatingTitleLabel.text = nil
        floatingTitleLabel.alpha = 0.0
        subtitleLabel.text = nil
        subtitleLabel.alpha = 0.0
        badgeView.isHidden = false
        releaseDateBadge.isHidden = true
        releaseDateTextLabel.text = nil
        contentContainer.transform = .identity
        contentContainer.alpha = 1.0
        loadingIndicator.stopAnimating()
        disposeBag = DisposeBag()
    }

    // MARK: - Layout
    override func configureHierarchy() {
        contentView.addSubview(contentContainer)
        contentContainer.addSubview(imageContainerView)
        imageContainerView.addSubview(imageView)
        imageView.layer.addSublayer(gradientLayer)
        imageContainerView.addSubview(loadingIndicator)

        // 텍스트를 contentContainer에 오버레이로 배치 (셀 밖으로 튀어나갈 수 있음)
        contentContainer.addSubview(titleContainer)
        titleContainer.addSubview(floatingTitleLabel)
        titleContainer.addSubview(subtitleLabel)

        imageContainerView.addSubview(badgeView)

        // 출시일 뷰는 contentContainer 위에 (imageContainer 경계 위로 벗어나게)
        contentContainer.addSubview(releaseDateBadge)
        releaseDateBadge.addSubview(releaseDateTextLabel)

        // Favorite 버튼
        imageContainerView.addSubview(favoriteButton)
        favoriteButton.addTarget(self, action: #selector(favoriteButtonTapped), for: .touchUpInside)

        // Notification 버튼
        imageContainerView.addSubview(notificationButton)
        notificationButton.addTarget(self, action: #selector(notificationButtonTapped), for: .touchUpInside)

        // Bookmark 버튼
        imageContainerView.addSubview(bookmarkButton)
        bookmarkButton.addTarget(self, action: #selector(bookmarkButtonTapped), for: .touchUpInside)
    }
    
    override func configureLayout() {
        contentView.clipsToBounds = false
        contentView.backgroundColor = .clear
        backgroundColor = .clear

        // contentContainer는 contentView 전체를 차지
        contentContainer.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // titleContainer의 z-order를 최상위로 설정
        titleContainer.layer.zPosition = 100

        // imageContainer는 contentContainer 전체를 차지 (groupSize와 동일)
        imageContainerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        badgeView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(16)
        }

        releaseDateBadge.snp.makeConstraints { make in
            make.centerY.equalTo(imageContainerView.snp.top)
            make.centerX.equalTo(imageContainerView)
        }
        releaseDateBadge.layer.zPosition = 200

        releaseDateTextLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(12)
            make.top.bottom.equalToSuperview().inset(8)
        }

        loadingIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        bookmarkButton.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(12)
            make.trailing.equalTo(favoriteButton.snp.leading).offset(-8)
            make.size.equalTo(40)
        }

        favoriteButton.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(12)
            make.trailing.equalToSuperview().inset(12)
            make.size.equalTo(40)
        }

        notificationButton.snp.makeConstraints { make in
            make.top.equalTo(favoriteButton.snp.bottom).offset(8)
            make.trailing.equalToSuperview().inset(12)
            make.size.equalTo(40)
        }

        // titleContainer는 이미지 하단에 오버레이로 배치, 셀 밖으로 살짝 튀어나옴
        titleContainer.snp.makeConstraints { make in
            make.leading.equalTo(imageContainerView.snp.leading).offset(-20) // 셀 경계를 넘어감
            make.trailing.equalTo(imageContainerView.snp.trailing).inset(20)
            make.bottom.equalTo(imageContainerView.snp.bottom).inset(20)
        }

        floatingTitleLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(floatingTitleLabel.snp.bottom).offset(4)
            make.leading.trailing.bottom.equalToSuperview()
        }

        // 그림자
        imageContainerView.layer.shadowColor = UIColor.systemBackground.cgColor
        imageContainerView.layer.shadowOpacity = 0.3
        imageContainerView.layer.shadowOffset = CGSize(width: 0, height: 8)
        imageContainerView.layer.shadowRadius = 16

        layer.masksToBounds = false
        contentView.layer.masksToBounds = false
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        // 그라디에이션 레이어 크기를 이미지뷰와 정확히 동기화
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradientLayer.frame = imageView.bounds
        CATransaction.commit()

        // 스켈레톤 프레임 업데이트
        imageView.updateSkeletonFrame()
    }

    // MARK: - Configuration
    func configure(with game: Game, showOnlyNotification: Bool = false, showOnlyFavorite: Bool = false) {
        currentGameId = game.id
        floatingTitleLabel.text = game.name

        // 버튼 표시 로직
        if showOnlyNotification {
            // upcomingGames: 알림 버튼만 오른쪽 위에
            favoriteButton.isHidden = true
            bookmarkButton.isHidden = true
            notificationButton.isHidden = false

            notificationButton.isSelected = NotificationManager.shared.isNotificationEnabled(gameId: game.id)

            // 알림 버튼을 오른쪽 위로 재배치
            notificationButton.snp.remakeConstraints { make in
                make.top.equalToSuperview().inset(12)
                make.trailing.equalToSuperview().inset(12)
                make.size.equalTo(40)
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

        } else if showOnlyFavorite {
            // popularGames, freeGames: 좋아요 버튼만 오른쪽 위에
            favoriteButton.isHidden = false
            bookmarkButton.isHidden = true
            notificationButton.isHidden = true

            favoriteButton.isSelected = FavoriteManager.shared.isFavorite(gameId: game.id)

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

        } else {
            // 기본: 모든 버튼 표시 (기존 로직 유지)
            favoriteButton.isHidden = false
            bookmarkButton.isHidden = false
            notificationButton.isHidden = true

            favoriteButton.isSelected = FavoriteManager.shared.isFavorite(gameId: game.id)
            bookmarkButton.isSelected = ReadingManager.shared.isReading(gameId: game.id)

            // 실시간 동기화
            FavoriteManager.shared.favoriteStatusChanged
                .filter { [weak self] (gameId, _) in
                    gameId == self?.currentGameId
                }
                .observe(on: MainScheduler.instance)
                .subscribe(onNext: { [weak self] (_, isFavorite) in
                    self?.favoriteButton.isSelected = isFavorite
                })
                .disposed(by: disposeBag)

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

        // 부제목 (장르)
        let genreNames = game.genres.map { $0.name }
        subtitleLabel.text = genreNames.prefix(2).joined(separator: " • ")

        if showOnlyNotification {
            // Upcoming 섹션: 배지 숨김, 출시일 표시
            badgeView.isHidden = true
            releaseDateBadge.isHidden = false
            if let released = game.released {
                // "2025-10-16" 형태를 "16 OCT 2025" 형태로 변환
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"

                if let date = dateFormatter.date(from: released) {
                    let outputFormatter = DateFormatter()
                    outputFormatter.dateFormat = "dd MMM yyyy"
                    outputFormatter.locale = Locale(identifier: "en_US")
                    releaseDateTextLabel.text = outputFormatter.string(from: date).uppercased()
                } else {
                    releaseDateTextLabel.text = released
                }
            }
        } else {
            // Popular 섹션: 별점 배지 표시, 출시일 숨김
            badgeView.isHidden = false
            badgeView.configure(rating: game.rating)
            releaseDateBadge.isHidden = true
        }

        // VoiceOver 접근성
        isAccessibilityElement = true
        accessibilityLabel = "\(game.name), Rating: \(String(format: "%.1f", game.rating))"
        accessibilityValue = genreNames.prefix(2).joined(separator: ", ")
        accessibilityHint = "Double tap to view details"

        // 이미지 로딩
        imageView.image = nil

        guard let backgroundImageString = game.backgroundImage,
              let imageURL = URL(string: backgroundImageString) else {
            print("이미지 URL 없음: \(game.name)")
            imageView.image = UIImage(named: "noImage")
            imageView.hideSkeleton()
            return
        }
        loadingIndicator.startAnimating()
        imageView.showSkeleton()

        imageView.kf.setImage(
            with: imageURL,
            placeholder: UIImage(named: "noImage"),
            options: [
                .transition(.fade(0.2)),
                .cacheOriginalImage
            ],
            completionHandler: { [weak self] result in
                self?.loadingIndicator.stopAnimating()
                self?.imageView.hideSkeleton()
                // 이미지 로드 완료 후 그라디에이션 레이어 프레임 업데이트
                self?.setNeedsLayout()
                self?.layoutIfNeeded()
            }
        )
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
