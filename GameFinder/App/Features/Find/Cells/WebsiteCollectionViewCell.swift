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
        var config = UIButton.Configuration.plain()
        config.title = "웹사이트 방문하기"
        config.image = UIImage(systemName: "arrow.up.right.square")
        config.imagePlacement = .trailing
        config.imagePadding = 8
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)

        let button = UIButton(configuration: config)
        button.contentHorizontalAlignment = .leading
        button.titleLabel?.font = .Body.regular14
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
