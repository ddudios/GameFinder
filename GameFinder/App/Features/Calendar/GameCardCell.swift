//
//  GameCardCell.swift
//  GameFinder
//
//  Created by Suji Jang on 1/27/26.
//

import UIKit
import SnapKit
import Kingfisher

final class GameCardCell: UICollectionViewCell {

    // MARK: - UI Components
    private let backgroundImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        imageView.backgroundColor = .systemGray5
        return imageView
    }()


    private let titleLabel = {
        let label = UILabel()
        label.font = .Title.bold16
        label.textColor = .white
        label.textAlignment = .left
        label.numberOfLines = 2
        // 텍스트 그림자 추가 (가독성 향상)
        label.layer.shadowColor = UIColor.black.cgColor
        label.layer.shadowOffset = CGSize(width: 0, height: 1)
        label.layer.shadowOpacity = 0.8
        label.layer.shadowRadius = 2
        return label
    }()

    private let ratingStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 4
        stackView.alignment = .center
        return stackView
    }()

    private let starImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "star.fill")
        imageView.tintColor = .Signature
        imageView.contentMode = .scaleAspectFit
        // 아이콘 그림자 추가 (가독성 향상)
        imageView.layer.shadowColor = UIColor.black.cgColor
        imageView.layer.shadowOffset = CGSize(width: 0, height: 1)
        imageView.layer.shadowOpacity = 0.8
        imageView.layer.shadowRadius = 2
        return imageView
    }()

    private let ratingLabel = {
        let label = UILabel()
        label.font = .NanumBarunGothic.bold12
        label.textColor = .white
        // 텍스트 그림자 추가 (가독성 향상)
        label.layer.shadowColor = UIColor.black.cgColor
        label.layer.shadowOffset = CGSize(width: 0, height: 1)
        label.layer.shadowOpacity = 0.8
        label.layer.shadowRadius = 2
        return label
    }()

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupUI() {
        contentView.addSubview(backgroundImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(ratingStackView)

        ratingStackView.addArrangedSubview(starImageView)
        ratingStackView.addArrangedSubview(ratingLabel)

        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(ratingStackView.snp.top).offset(-8)
        }

        ratingStackView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(16)
        }

        starImageView.snp.makeConstraints { make in
            make.size.equalTo(14)
        }

        // 그림자 효과
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOpacity = 0.2
        contentView.layer.shadowOffset = CGSize(width: 0, height: 2)
        contentView.layer.shadowRadius = 8
    }

    // MARK: - Configuration
    func configure(with game: Game) {
        titleLabel.text = game.name
        ratingLabel.text = String(format: "%.1f", game.rating)

        if let backgroundImageString = game.backgroundImage,
           let imageURL = URL(string: backgroundImageString) {
            backgroundImageView.showSkeletonLoading()
            backgroundImageView.kf.setImage(
                with: imageURL,
                placeholder: UIImage(named: "noImage"),
                options: [
                    .transition(.fade(0.2)),
                    .cacheOriginalImage
                ],
                completionHandler: { [weak self] _ in
                    self?.backgroundImageView.hideSkeletonLoading()
                }
            )
        } else {
            backgroundImageView.image = UIImage(named: "noImage")
            backgroundImageView.hideSkeletonLoading()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        backgroundImageView.kf.cancelDownloadTask()
        backgroundImageView.image = nil
        backgroundImageView.hideSkeletonLoading()
        titleLabel.text = nil
        ratingLabel.text = nil
    }
}
