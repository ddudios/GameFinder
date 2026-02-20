//
//  GameTitleCollectionViewCell.swift
//  GameFinder
//
//  Created by Codex on 2/20/26.
//

import UIKit
import SnapKit

final class GameTitleCollectionViewCell: BaseCollectionViewCell {

    private let titleLabel = {
        let label = UILabel()
        label.font = .Title.bold14
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }()

    override func configureHierarchy() {
        contentView.addSubview(titleLabel)
    }

    override func configureLayout() {
        titleLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func configure(with title: String) {
        titleLabel.text = title
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
    }
}
