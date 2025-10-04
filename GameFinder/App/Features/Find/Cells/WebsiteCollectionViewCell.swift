//
//  WebsiteCollectionViewCell.swift
//  GameFinder
//
//  Created by Suji Jang on 10/5/25.
//

import UIKit
import SnapKit

final class WebsiteCollectionViewCell: BaseCollectionViewCell {

    private let titleLabel = {
        let label = UILabel()
        label.font = .Title.bold14
        label.textColor = .secondaryLabel
        label.text = "공식 웹사이트"
        return label
    }()

    private let linkButton = {
        let button = UIButton(type: .system)
        button.setTitle("웹사이트 방문하기", for: .normal)
        button.titleLabel?.font = .Body.regular14
        button.contentHorizontalAlignment = .left
        button.setImage(UIImage(systemName: "arrow.up.right.square"), for: .normal)
        button.semanticContentAttribute = .forceRightToLeft
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
        return button
    }()

    private var websiteURL: String?

    override func configureHierarchy() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(linkButton)

        linkButton.addTarget(self, action: #selector(linkButtonTapped), for: .touchUpInside)
    }

    override func configureLayout() {
        titleLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        linkButton.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(44)
        }
    }

    func configure(with website: String?) {
        self.websiteURL = website
        linkButton.isEnabled = website != nil
    }

    @objc private func linkButtonTapped() {
        guard let urlString = websiteURL,
              let url = URL(string: urlString),
              UIApplication.shared.canOpenURL(url) else {
            return
        }
        UIApplication.shared.open(url)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        websiteURL = nil
    }
}
