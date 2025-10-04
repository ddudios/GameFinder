//
//  TagsCollectionViewCell.swift
//  GameFinder
//
//  Created by Suji Jang on 10/5/25.
//

import UIKit
import SnapKit

final class TagsCollectionViewCell: BaseCollectionViewCell {

    private let titleLabel = {
        let label = UILabel()
        label.font = .Title.bold14
        label.textColor = .secondaryLabel
        label.text = "태그"
        return label
    }()

    private let tagsContainerView = {
        let view = UIView()
        return view
    }()

    override func configureHierarchy() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(tagsContainerView)
    }

    override func configureLayout() {
        titleLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        tagsContainerView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    func configure(with tags: [GameTag]) {
        // 기존 태그 뷰 제거
        tagsContainerView.subviews.forEach { $0.removeFromSuperview() }

        var previousView: UIView?
        var rowViews: [UIView] = []
        var currentRowWidth: CGFloat = 0
        let maxWidth = UIScreen.main.bounds.width - 64 // 좌우 패딩 고려
        let spacing: CGFloat = 8

        // 최대 10개의 태그만 표시
        let displayTags = Array(tags.prefix(10))

        for tag in displayTags {
            let tagView = createTagView(with: tag.name)
            let tagWidth = tagView.intrinsicContentSize.width

            // 현재 행에 추가 가능한지 확인
            if currentRowWidth + tagWidth + spacing > maxWidth, !rowViews.isEmpty {
                // 새로운 행 시작
                previousView = arrangeRow(rowViews, below: previousView)
                rowViews.removeAll()
                currentRowWidth = 0
            }

            rowViews.append(tagView)
            currentRowWidth += tagWidth + spacing
        }

        // 마지막 행 배치
        if !rowViews.isEmpty {
            arrangeRow(rowViews, below: previousView)
        }
    }

    private func createTagView(with text: String) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .systemGray5
        containerView.layer.cornerRadius = 12

        let label = UILabel()
        label.text = text
        label.font = .Body.regular12
        label.textColor = .label

        containerView.addSubview(label)
        label.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(12)
            make.top.bottom.equalToSuperview().inset(6)
        }

        tagsContainerView.addSubview(containerView)
        return containerView
    }

    @discardableResult
    private func arrangeRow(_ views: [UIView], below previousView: UIView?) -> UIView {
        var leadingAnchor = tagsContainerView.snp.leading
        let spacing: CGFloat = 8

        for view in views {
            view.snp.makeConstraints { make in
                make.leading.equalTo(leadingAnchor).offset(leadingAnchor == tagsContainerView.snp.leading ? 0 : spacing)

                if let previous = previousView {
                    make.top.equalTo(previous.snp.bottom).offset(spacing)
                } else {
                    make.top.equalToSuperview()
                }

                if view == views.last {
                    make.bottom.equalToSuperview()
                }
            }
            leadingAnchor = view.snp.trailing
        }

        return views.last ?? tagsContainerView
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        tagsContainerView.subviews.forEach { $0.removeFromSuperview() }
    }
}
