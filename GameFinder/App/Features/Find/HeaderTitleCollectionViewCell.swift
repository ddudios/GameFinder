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

    private let badgeView = {
        let view = UIView()
        view.backgroundColor = .Signiture
        view.layer.cornerRadius = 12
        view.isHidden = true
        return view
    }()

    private let badgeLabel = {
        let label = UILabel()
        label.font = .Body.bold12
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()

    private let releaseDateLabel = {
        let label = UILabel()
        label.font = .Body.regular14
        label.textColor = .systemGray
        label.textAlignment = .right
        label.isHidden = true
        return label
    }()

    override func configureHierarchy() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(badgeView)
        badgeView.addSubview(badgeLabel)
        contentView.addSubview(releaseDateLabel)
    }

    override func configureLayout() {
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(20)
            make.leading.equalToSuperview().inset(40)
            make.trailing.equalToSuperview().inset(20)
        }

        badgeView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.trailing.equalToSuperview().inset(20)
            make.height.equalTo(24)
        }

        badgeLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
        }

        releaseDateLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.trailing.equalTo(badgeView.snp.leading).offset(-8)
            make.bottom.equalToSuperview().inset(20)
        }
    }

    override func configureView() {
        super.configureView()
        backgroundColor = .clear
    }

    func configure(with title: String, releaseDate: String? = nil) {
        titleLabel.text = title

        // COMING SOON 섹션의 첫번째 셀에는 타이틀만 표시
        badgeView.isHidden = true
        releaseDateLabel.isHidden = true
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        releaseDateLabel.text = nil
        badgeView.isHidden = true
        releaseDateLabel.isHidden = true
    }
}
