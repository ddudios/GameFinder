//
//  GenreCollectionViewCell.swift
//  GameFinder
//
//  Created by Suji Jang on 10/5/25.
//

import UIKit
import SnapKit

final class GenreCollectionViewCell: BaseCollectionViewCell {

    private let titleLabel = {
        let label = UILabel()
        label.font = .Title.bold14
        label.textColor = .secondaryLabel
        label.text = "장르"
        return label
    }()

    private let genreLabel = {
        let label = UILabel()
        label.font = .Body.regular14
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }()

    override func configureHierarchy() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(genreLabel)
    }

    override func configureLayout() {
        titleLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        genreLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    func configure(with genres: [GameGenre]) {
        let genreNames = genres.map { $0.name }
        genreLabel.text = genreNames.joined(separator: ", ")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        genreLabel.text = nil
    }
}
