//
//  DeveloperPublisherCollectionViewCell.swift
//  GameFinder
//
//  Created by Suji Jang on 10/5/25.
//

import UIKit
import SnapKit

final class DeveloperPublisherCollectionViewCell: BaseCollectionViewCell {

    private let containerView = {
        let view = UIView()
        view.backgroundColor = .quaternaryLabel
        view.layer.cornerRadius = 12
        return view
    }()

    private let developerLabel = {
        let label = UILabel()
        label.font = .Body.regular12
        label.textColor = .secondaryLabel
        label.text = L10n.GameDetail.developer
        return label
    }()

    private let developerValueLabel = {
        let label = UILabel()
        label.font = .Title.bold14
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }()

    private let publisherLabel = {
        let label = UILabel()
        label.font = .Body.regular12
        label.textColor = .secondaryLabel
        label.text = L10n.GameDetail.publisher
        return label
    }()

    private let publisherValueLabel = {
        let label = UILabel()
        label.font = .Title.bold14
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }()

    private let separatorView = {
        let view = UIView()
        view.backgroundColor = .separator
        return view
    }()

    override func configureHierarchy() {
        contentView.addSubview(containerView)
        containerView.addSubview(developerLabel)
        containerView.addSubview(developerValueLabel)
        containerView.addSubview(separatorView)
        containerView.addSubview(publisherLabel)
        containerView.addSubview(publisherValueLabel)
    }

    override func configureLayout() {
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        developerLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(16)
        }

        developerValueLabel.snp.makeConstraints { make in
            make.top.equalTo(developerLabel.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        separatorView.snp.makeConstraints { make in
            make.top.equalTo(developerValueLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(1)
        }

        publisherLabel.snp.makeConstraints { make in
            make.top.equalTo(separatorView.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        publisherValueLabel.snp.makeConstraints { make in
            make.top.equalTo(publisherLabel.snp.bottom).offset(4)
            make.leading.trailing.bottom.equalToSuperview().inset(16)
        }
    }

    func configure(developers: [GameDeveloper], publishers: [GamePublisher]) {
        let developerNames = developers.map { $0.name }
        developerValueLabel.text = developerNames.isEmpty ? L10n.GameDetail.noData : developerNames.joined(separator: ", ")

        let publisherNames = publishers.map { $0.name }
        publisherValueLabel.text = publisherNames.isEmpty ? L10n.GameDetail.noData : publisherNames.joined(separator: ", ")

        // 개발사와 퍼블리셔가 모두 없으면 숨김
        contentView.isHidden = developers.isEmpty && publishers.isEmpty
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        developerValueLabel.text = nil
        publisherValueLabel.text = nil
        contentView.isHidden = false
    }
}
