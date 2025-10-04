//
//  AgeRatingCollectionViewCell.swift
//  GameFinder
//
//  Created by Suji Jang on 10/5/25.
//

import UIKit
import SnapKit

final class AgeRatingCollectionViewCell: BaseCollectionViewCell {

    private let titleLabel = {
        let label = UILabel()
        label.font = .Title.bold14
        label.textColor = .secondaryLabel
        label.text = "연령 등급"
        return label
    }()

    private let ratingLabel = {
        let label = UILabel()
        label.font = .Body.regular14
        label.textColor = .label
        return label
    }()

    override func configureHierarchy() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(ratingLabel)
    }

    override func configureLayout() {
        titleLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        ratingLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    func configure(with esrbRating: GameESRBRating?) {
        if let rating = esrbRating {
            ratingLabel.text = rating.name
            contentView.isHidden = false
        } else {
            ratingLabel.text = nil
            contentView.isHidden = true
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        ratingLabel.text = nil
        contentView.isHidden = false
    }
}
