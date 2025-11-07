//
//  HeaderTitleCollectionViewCell.swift
//  GameFinder
//
//  Created by Suji Jang on 10/4/25.
//

import UIKit
import SnapKit

final class HeaderTitleCollectionViewCell: BaseCollectionViewCell {

    private let titleLabel = {
        let label = UILabel()
        label.font = .Heading.heavy24
        label.textColor = .label
        label.textAlignment = .right
        label.numberOfLines = 0
        return label
    }()

    override func configureHierarchy() {
        contentView.addSubview(titleLabel)
    }

    override func configureLayout() {
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(20)
            make.leading.equalToSuperview().inset(40)
            make.trailing.equalToSuperview().inset(20)
        }
    }

    override func configureView() {
        super.configureView()
        backgroundColor = .clear
    }

    func configure(with title: String, releaseDate: String? = nil) {
        titleLabel.text = title
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
    }
}
