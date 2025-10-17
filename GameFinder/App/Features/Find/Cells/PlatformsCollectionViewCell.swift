//
//  PlatformsCollectionViewCell.swift
//  GameFinder
//
//  Created by Suji Jang on 10/5/25.
//

import UIKit
import SnapKit

final class PlatformsCollectionViewCell: BaseCollectionViewCell {

    private let titleLabel = {
        let label = UILabel()
        label.font = .Title.bold14
        label.textColor = .secondaryLabel
        label.text = L10n.GameDetail.platform
        return label
    }()

    private let platformsLabel = {
        let label = UILabel()
        label.font = .Body.regular14
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }()

    override func configureHierarchy() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(platformsLabel)
    }

    override func configureLayout() {
        titleLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        platformsLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    func configure(with platforms: [GamePlatform]) {
        let platformNames = platforms.map { $0.name }
        platformsLabel.text = platformNames.joined(separator: ", ")
        contentView.isHidden = platforms.isEmpty
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        platformsLabel.text = nil
        contentView.isHidden = false
    }
}
