//
//  RatingCollectionViewCell.swift
//  GameFinder
//
//  Created by Suji Jang on 10/5/25.
//

import UIKit
import SnapKit

final class RatingCollectionViewCell: BaseCollectionViewCell {

    private let titleLabel = {
        let label = UILabel()
        label.font = .Title.bold14
        label.textColor = .secondaryLabel
        label.text = "평점"
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
        label.font = .Heading.heavy24
        label.textColor = .label
        return label
    }()

    private let ratingsCountLabel = {
        let label = UILabel()
        label.font = .Body.regular14
        label.textColor = .secondaryLabel
        return label
    }()

    private lazy var ratingStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [starImageView, ratingLabel])
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.alignment = .center
        return stackView
    }()

    override func configureHierarchy() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(ratingStackView)
        contentView.addSubview(ratingsCountLabel)
    }

    override func configureLayout() {
        titleLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        ratingStackView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.equalToSuperview()
        }

        starImageView.snp.makeConstraints { make in
            make.size.equalTo(24)
        }

        ratingsCountLabel.snp.makeConstraints { make in
            make.top.equalTo(ratingStackView.snp.bottom).offset(4)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    func configure(rating: Double?, ratingsCount: Int?) {
        if let rating = rating {
            ratingLabel.text = String(format: "%.1f", rating)
        } else {
            ratingLabel.text = "N/A"
        }

        if let count = ratingsCount {
            ratingsCountLabel.text = "\(count.formatted())명의 평가"
        } else {
            ratingsCountLabel.text = "평가 없음"
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        ratingLabel.text = nil
        ratingsCountLabel.text = nil
    }
}
