//
//  DescriptionCollectionViewCell.swift
//  GameFinder
//
//  Created by Suji Jang on 10/5/25.
//

import UIKit
import SnapKit

final class DescriptionCollectionViewCell: BaseCollectionViewCell {

    private let titleLabel = {
        let label = UILabel()
        label.font = .Title.bold14
        label.textColor = .secondaryLabel
        label.text = L10n.GameDetail.description
        return label
    }()

    private let descriptionLabel = {
        let label = UILabel()
        label.font = .Body.regular14
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }()

    override func configureHierarchy() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(descriptionLabel)
    }

    override func configureLayout() {
        titleLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    func configure(with description: String?) {
        if let description = description, !description.isEmpty {
            descriptionLabel.text = description
            contentView.isHidden = false
        } else {
            descriptionLabel.text = nil
            contentView.isHidden = true
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        descriptionLabel.text = nil
        contentView.isHidden = false
    }
}
