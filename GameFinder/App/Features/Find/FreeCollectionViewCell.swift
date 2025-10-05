//
//  FinderCollectionViewCell.swift
//  GameFinder
//
//  Created by Suji Jang on 9/30/25.
//

import UIKit
import SnapKit
import RxSwift
import Kingfisher

final class FreeCollectionViewCell: BaseCollectionViewCell {

    private let iconImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = .systemGray5
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 16
        imageView.clipsToBounds = true
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

    private let starImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "star.fill")
        imageView.tintColor = .Signiture
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let ratingLabel = {
        let label = UILabel()
        label.font = .NanumBarunGothic.regular12
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        return label
    }()

    private lazy var ratingStackView = {
        let stackView = UIStackView(arrangedSubviews: [starImageView, ratingLabel])
        stackView.axis = .horizontal
        stackView.spacing = 4
        stackView.alignment = .center
        return stackView
    }()

    private lazy var textStackView = {
        let stackView = UIStackView(arrangedSubviews: [titleLabel, genreLabel, ratingStackView])
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.alignment = .leading
        return stackView
    }()

    let favoriteButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(systemName: "heart"), for: .normal)
        button.setImage(UIImage(systemName: "heart.fill"), for: .selected)
        button.tintColor = .systemRed
        button.backgroundColor = .clear
        return button
    }()

    var onFavoriteButtonTapped: ((Int) -> Void)?
    private var currentGameId: Int?
    var disposeBag = DisposeBag()

    override func layoutSubviews() {
        super.layoutSubviews()
        iconImageView.updateSkeletonFrame()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        iconImageView.kf.cancelDownloadTask()
        iconImageView.image = nil
        iconImageView.hideSkeleton()
        titleLabel.text = nil
        genreLabel.text = nil
        ratingLabel.text = nil
        disposeBag = DisposeBag()
    }

    func configure(with game: Game) {
        currentGameId = game.id
        titleLabel.text = game.name

        // Favorite 상태 설정
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

        // 장르
        let genreNames = game.genres.map { $0.name }
        genreLabel.text = genreNames.prefix(2).joined(separator: " • ")

        // 평점
        ratingLabel.text = String(format: "%.1f", game.rating)

        // 이미지 로딩
        if let backgroundImageString = game.backgroundImage,
           let imageURL = URL(string: backgroundImageString) {
            iconImageView.showSkeleton()
            iconImageView.kf.setImage(
                with: imageURL,
                placeholder: UIImage(named: "noImage"),
                options: [
                    .transition(.fade(0.2)),
                    .cacheOriginalImage
                ],
                completionHandler: { [weak self] _ in
                    self?.iconImageView.hideSkeleton()
                }
            )
        } else {
            iconImageView.image = UIImage(named: "noImage")
            iconImageView.hideSkeleton()
        }
    }

    override func configureHierarchy() {
        contentView.addSubview(iconImageView)
        contentView.addSubview(textStackView)
        contentView.addSubview(favoriteButton)
        favoriteButton.addTarget(self, action: #selector(favoriteButtonTapped), for: .touchUpInside)
    }

    override func configureLayout() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        iconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(80)
        }

        starImageView.snp.makeConstraints { make in
            make.size.equalTo(12)
        }

        textStackView.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(16)
            make.trailing.equalTo(favoriteButton.snp.leading).offset(-8)
            make.centerY.equalToSuperview()
        }

        favoriteButton.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(8)
            make.trailing.equalToSuperview().inset(16)
            make.size.equalTo(36)
        }
    }

    // MARK: - Actions
    @objc private func favoriteButtonTapped() {
        guard let gameId = currentGameId else { return }
        onFavoriteButtonTapped?(gameId)
    }
}
