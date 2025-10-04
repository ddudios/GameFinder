//
//  RatingAndAgeCollectionViewCell.swift
//  GameFinder
//
//  Created by Suji Jang on 10/5/25.
//

import UIKit
import SnapKit

final class RatingAndAgeCollectionViewCell: BaseCollectionViewCell {

    // 평점 섹션
    private let ratingContainerView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 12
        return view
    }()

    private let ratingTitleLabel = {
        let label = UILabel()
        label.font = .Body.regular12
        label.textColor = .secondaryLabel
        label.text = "평점"
        return label
    }()

    private let starImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "star.fill")
        imageView.tintColor = .systemOrange
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let ratingLabel = {
        let label = UILabel()
        label.font = .Heading.heavy24
        label.textColor = .label
        return label
    }()

    private let ratingsCountLabel = {
        let label = UILabel()
        label.font = .Body.regular12
        label.textColor = .secondaryLabel
        return label
    }()

    // 연령 등급 섹션
    private let ageRatingContainerView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 12
        return view
    }()

    private let ageRatingTitleLabel = {
        let label = UILabel()
        label.font = .Body.regular12
        label.textColor = .secondaryLabel
        label.text = "연령 등급"
        return label
    }()

    private let ageRatingLabel = {
        let label = UILabel()
        label.font = .Title.bold16
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }()

    private lazy var ratingStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [starImageView, ratingLabel])
        stackView.axis = .horizontal
        stackView.spacing = 4
        stackView.alignment = .center
        return stackView
    }()

    override func configureHierarchy() {
        contentView.addSubview(ratingContainerView)
        ratingContainerView.addSubview(ratingTitleLabel)
        ratingContainerView.addSubview(ratingStackView)
        ratingContainerView.addSubview(ratingsCountLabel)

        contentView.addSubview(ageRatingContainerView)
        ageRatingContainerView.addSubview(ageRatingTitleLabel)
        ageRatingContainerView.addSubview(ageRatingLabel)
    }

    override func configureLayout() {
        // 평점 컨테이너
        ratingContainerView.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.48)
        }

        ratingTitleLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(12)
        }

        ratingStackView.snp.makeConstraints { make in
            make.top.equalTo(ratingTitleLabel.snp.bottom).offset(4)
            make.leading.equalToSuperview().inset(12)
        }

        starImageView.snp.makeConstraints { make in
            make.size.equalTo(20)
        }

        ratingsCountLabel.snp.makeConstraints { make in
            make.top.equalTo(ratingStackView.snp.bottom).offset(2)
            make.leading.trailing.bottom.equalToSuperview().inset(12)
        }

        // 연령 등급 컨테이너
        ageRatingContainerView.snp.makeConstraints { make in
            make.trailing.top.bottom.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.48)
        }

        ageRatingTitleLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(12)
        }

        ageRatingLabel.snp.makeConstraints { make in
            make.top.equalTo(ageRatingTitleLabel.snp.bottom).offset(4)
            make.leading.trailing.bottom.equalToSuperview().inset(12)
        }
    }

    func configure(rating: Double?, ratingsCount: Int?, ageRating: GameESRBRating?) {
        // 평점 설정
        if let rating = rating {
            ratingLabel.text = String(format: "%.1f", rating)
        } else {
            ratingLabel.text = "N/A"
        }

        if let count = ratingsCount {
            ratingsCountLabel.text = "\(count.formatted())명"
        } else {
            ratingsCountLabel.text = "평가 없음"
        }

        // 연령 등급 설정
        if let rating = ageRating {
            ageRatingLabel.text = rating.name
        } else {
            ageRatingLabel.text = "정보 없음"
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        ratingLabel.text = nil
        ratingsCountLabel.text = nil
        ageRatingLabel.text = nil
    }
}
