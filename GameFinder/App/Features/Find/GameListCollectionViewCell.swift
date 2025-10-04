//
//  GameListCollectionViewCell.swift
//  GameFinder
//
//  Created by Suji Jang on 10/4/25.
//

import UIKit
import SnapKit
import Kingfisher

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
        label.textColor = .white
        label.numberOfLines = 1
        return label
    }()

    private let genreLabel = {
        let label = UILabel()
        label.font = .Body.regular12
        label.textColor = .systemGray
        label.numberOfLines = 1
        return label
    }()

    private let ratingLabel = {
        let label = UILabel()
        label.font = .NanumBarunGothic.bold12
        label.textColor = .white
        return label
    }()

    private let starImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "star.fill")
        imageView.tintColor = .systemOrange
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let separatorView = {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        return view
    }()

    override func configureHierarchy() {
        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(genreLabel)
        contentView.addSubview(starImageView)
        contentView.addSubview(ratingLabel)
        contentView.addSubview(separatorView)
    }

    override func configureLayout() {
        iconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.size.equalTo(80)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(16)
            make.top.equalToSuperview().inset(16)
            make.trailing.equalToSuperview().inset(16)
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

    func configure(with game: Game) {
        titleLabel.text = game.name

        let genreNames = game.genres.map { $0.name }
        genreLabel.text = genreNames.prefix(2).joined(separator: " • ")

        ratingLabel.text = String(format: "%.1f", game.rating)

        if let backgroundImageString = game.backgroundImage,
           let imageURL = URL(string: backgroundImageString) {
            iconImageView.kf.setImage(
                with: imageURL,
                options: [
                    .transition(.fade(0.2)),
                    .cacheOriginalImage
                ]
            )
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        iconImageView.kf.cancelDownloadTask()
        iconImageView.image = nil
        titleLabel.text = nil
        genreLabel.text = nil
        ratingLabel.text = nil
    }
}
