//
//  ReleaseAndRatingCollectionViewCell.swift
//  GameFinder
//
//  Created by Suji Jang on 10/5/25.
//

import UIKit
import SnapKit

final class ReleaseAndRatingCollectionViewCell: BaseCollectionViewCell {

    private let calendarImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "calendar")
        imageView.tintColor = .secondaryLabel
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let releaseDateLabel = {
        let label = UILabel()
        label.font = .Body.regular14
        label.textColor = .secondaryLabel
        return label
    }()

    private let separatorLabel = {
        let label = UILabel()
        label.font = .Body.regular14
        label.textColor = .secondaryLabel
        label.text = "|"
        return label
    }()

    private let starImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "star.fill")
        imageView.tintColor = .secondaryLabel
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let ratingLabel = {
        let label = UILabel()
        label.font = .Body.regular14
        label.textColor = .secondaryLabel
        return label
    }()

    private let ratingsCountLabel = {
        let label = UILabel()
        label.font = .Body.regular14
        label.textColor = .secondaryLabel
        return label
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            calendarImageView,
            releaseDateLabel,
            separatorLabel,
            starImageView,
            ratingLabel,
            ratingsCountLabel
        ])
        stackView.axis = .horizontal
        stackView.spacing = 6
        stackView.alignment = .center
        return stackView
    }()

    override func configureHierarchy() {
        contentView.addSubview(stackView)
    }

    override func configureLayout() {
        calendarImageView.snp.makeConstraints { make in
            make.size.equalTo(16)
        }

        starImageView.snp.makeConstraints { make in
            make.size.equalTo(16)
        }

        stackView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.bottom.equalToSuperview()
        }
    }

    func configure(releaseDate: String?, rating: Double?, ratingsCount: Int?) {
        let hasReleaseDate = releaseDate != nil
        let hasRating = rating != nil
        let hasRatingsCount = ratingsCount != nil

        // 출시일 설정
        if let released = releaseDate {
            releaseDateLabel.text = released
            calendarImageView.isHidden = false
            releaseDateLabel.isHidden = false
        } else {
            calendarImageView.isHidden = true
            releaseDateLabel.isHidden = true
        }

        // 평점 설정
        if let rating = rating {
            ratingLabel.text = String(format: "%.1f", rating)
            starImageView.isHidden = false
            ratingLabel.isHidden = false
        } else {
            starImageView.isHidden = true
            ratingLabel.isHidden = true
        }

        // 평가 수 설정
        if let count = ratingsCount {
            ratingsCountLabel.text = "(\(count.formatted()))"
            ratingsCountLabel.isHidden = false
        } else {
            ratingsCountLabel.isHidden = true
        }

        // 구분자 표시 여부
        separatorLabel.isHidden = !(hasReleaseDate && (hasRating || hasRatingsCount))

        // 모든 정보가 없으면 전체 뷰 숨김
        contentView.isHidden = !hasReleaseDate && !hasRating && !hasRatingsCount
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        releaseDateLabel.text = nil
        ratingLabel.text = nil
        ratingsCountLabel.text = nil
        calendarImageView.isHidden = false
        releaseDateLabel.isHidden = false
        starImageView.isHidden = false
        ratingLabel.isHidden = false
        ratingsCountLabel.isHidden = false
        separatorLabel.isHidden = false
        contentView.isHidden = false
    }
}
