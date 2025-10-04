//
//  HeaderTitleCollectionViewCell.swift
//  GameFinder
//
//  Created by Claude on 10/4/25.
//

import UIKit
import SnapKit

final class HeaderTitleCollectionViewCell: BaseCollectionViewCell {

    private let titleLabel = {
        let label = UILabel()
        label.font = .Heading.heavy24
        label.textColor = .white
        label.textAlignment = .right
        label.numberOfLines = 0
        return label
    }()

    override func configureHierarchy() {
        contentView.addSubview(titleLabel)
    }

    override func configureLayout() {
        titleLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 20, left: 40, bottom: 20, right: 20))
        }
    }

    override func configureView() {
        super.configureView()
        backgroundColor = .clear
    }

    func configure(with title: String) {
        titleLabel.text = title
    }
}
