//
//  FeaturedGameCell.swift
//  GameFinder
//
//  Created by Suji Jang on 9/30/25.
//

import UIKit
import SnapKit
import Kingfisher

final class FeaturedGameCell: BaseCollectionViewCell {

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
            UIColor.black.withAlphaComponent(0.6).cgColor
        ]
        layer.locations = [0.6, 1.0]
        layer.startPoint = CGPoint(x: 0.5, y: 0.0) // 상단 중앙
        layer.endPoint = CGPoint(x: 0.5, y: 1.0) // 하단 중앙
        return layer
    }()

    let badgeView = BadgeView()

    // 타이틀 컨테이너 (셀 경계를 넘어가도록)
    private let titleContainer = {
        let view = UIView()
        view.clipsToBounds = false
        return view
    }()

    let floatingTitleLabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .title1)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = UIColor.white.withAlphaComponent(1.0) // 완전 불투명
        label.numberOfLines = 2
        label.layer.shadowColor = UIColor.black.cgColor
        label.layer.shadowOpacity = 0.8
        label.layer.shadowOffset = CGSize(width: 0, height: 2)
        label.layer.shadowRadius = 4
        label.alpha = 0 // 초기값 숨김 (visibility용)
        return label
    }()

    let subtitleLabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = UIColor.white.withAlphaComponent(1.0) // 완전 불투명
        label.numberOfLines = 1
        label.alpha = 0 // 초기값 숨김 (visibility용)
        return label
    }()

    private let loadingIndicator = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.color = .white
        return indicator
    }()
    
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
        floatingTitleLabel.text = nil
        floatingTitleLabel.alpha = 0.0
        subtitleLabel.text = nil
        subtitleLabel.alpha = 0.0
        badgeView.alpha = 0.0
        contentContainer.transform = .identity
        contentContainer.alpha = 1.0
        loadingIndicator.stopAnimating()
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

        // 배지는 이미지 위에
        imageContainerView.addSubview(badgeView)
    }
    
    override func configureLayout() {
        // contentView clipsToBounds = false로 설정하여 타이틀이 경계 밖으로 나갈 수 있게
        contentView.clipsToBounds = false
        contentView.backgroundColor = .clear
        backgroundColor = .clear

        // contentContainer는 contentView 전체를 차지
        contentContainer.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // titleContainer의 z-order를 최상위로 설정
        titleContainer.layer.zPosition = 100

        // imageContainer는 4:3 비율 유지
        imageContainerView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(imageContainerView.snp.width).multipliedBy(3.0 / 4.0)
        }

        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        badgeView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(16)
        }

        loadingIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
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
        imageContainerView.layer.shadowColor = UIColor.black.cgColor
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
    }

    // MARK: - Configuration
    func configure(with game: Game) {
        floatingTitleLabel.text = game.name

        // 부제목 (장르)
        let genreNames = game.genres.map { $0.name }
        subtitleLabel.text = genreNames.prefix(2).joined(separator: " • ")

        // BadgeView에 별점 표시
        badgeView.configure(rating: game.rating)

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
            imageView.backgroundColor = .systemGray5
            return
        }
        loadingIndicator.startAnimating()

        imageView.kf.setImage(
            with: imageURL,
            options: [
                .transition(.fade(0.2)),
                .cacheOriginalImage
            ],
            completionHandler: { [weak self] result in
                self?.loadingIndicator.stopAnimating()
                // 이미지 로드 완료 후 그라디에이션 레이어 프레임 업데이트
                self?.setNeedsLayout()
                self?.layoutIfNeeded()
            }
        )
    }
}
