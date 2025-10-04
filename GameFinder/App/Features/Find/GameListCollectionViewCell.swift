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
        imageView.tintColor = .Signiture
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let releaseBadgeView = {
        let view = UIView()
        view.backgroundColor = UIColor.Signiture
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

    override func configureHierarchy() {
        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(genreLabel)
        contentView.addSubview(starImageView)
        contentView.addSubview(ratingLabel)
        contentView.addSubview(releaseStackView)
        releaseBadgeView.addSubview(releaseBadgeLabel)
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

    func configure(with game: Game, isUpcoming: Bool = false) {
        titleLabel.text = game.name

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
                            releaseBadgeLabel.text = "오늘"
                            releaseBadgeView.isHidden = false
                        } else if dayDifference == 1 {
                            releaseBadgeLabel.text = "내일"
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
        releaseDateLabel.text = nil
        releaseBadgeView.isHidden = true
        releaseStackView.isHidden = true
        starImageView.isHidden = false
        ratingLabel.isHidden = false
    }
}
