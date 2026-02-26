//
//  GenreAndTagsCollectionViewCell.swift
//  GameFinder
//
//  Created by Suji Jang on 10/5/25.
//

import UIKit
import SnapKit

private final class LeftAlignedFlowLayout: UICollectionViewFlowLayout {
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let attributes = super.layoutAttributesForElements(in: rect) else { return nil }

        var left = sectionInset.left
        var currentRowMaxY: CGFloat = -1

        return attributes.map { attribute in
            guard let copied = attribute.copy() as? UICollectionViewLayoutAttributes else {
                return attribute
            }

            guard copied.representedElementCategory == .cell else {
                return copied
            }

            if copied.frame.minY >= currentRowMaxY {
                left = sectionInset.left
            }

            copied.frame.origin.x = left
            left = copied.frame.maxX + minimumInteritemSpacing
            currentRowMaxY = max(currentRowMaxY, copied.frame.maxY)
            return copied
        }
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        true
    }
}

final class GenreAndTagsCollectionViewCell: BaseCollectionViewCell {

    private enum Layout {
        static let tagTopSpacing: CGFloat = 8
    }

    private let titleLabel = {
        let label = UILabel()
        label.font = .Title.bold14
        label.textColor = .secondaryLabel
        label.text = L10n.GameDetail.genre
        return label
    }()

    private let genreLabel = {
        let label = UILabel()
        label.font = .Body.regular14
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }()

    private lazy var tagsCollectionView: UICollectionView = {
        let layout = LeftAlignedFlowLayout()
        layout.scrollDirection = .vertical
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.isScrollEnabled = false
        collectionView.dataSource = self
        collectionView.register(TagCell.self, forCellWithReuseIdentifier: TagCell.identifier)
        return collectionView
    }()

    private var tags: [GameTag] = []
    private var shouldUpdateTagCollectionHeight = false
    private var lastMeasuredWidth: CGFloat = 0
    private var tagsCollectionTopConstraint: Constraint?
    private var tagsCollectionHeightConstraint: Constraint?

    override func configureHierarchy() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(genreLabel)
        contentView.addSubview(tagsCollectionView)
    }

    override func configureLayout() {
        titleLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        genreLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview()
        }

        tagsCollectionView.snp.makeConstraints { make in
            tagsCollectionTopConstraint = make.top.equalTo(genreLabel.snp.bottom).offset(Layout.tagTopSpacing).constraint
            make.leading.trailing.bottom.equalToSuperview()
            tagsCollectionHeightConstraint = make.height.equalTo(0).constraint
        }
    }

    func configure(genres: [GameGenre], tags: [GameTag]) {
        let genreNames = genres.map { $0.name }
        genreLabel.text = genreNames.joined(separator: ", ")

        self.tags = tags
        tagsCollectionView.reloadData()
        shouldUpdateTagCollectionHeight = true
        lastMeasuredWidth = 0
        updateTagCollectionHeightIfNeeded()
        setNeedsLayout()

        // 장르와 태그가 모두 없으면 전체 숨김
        contentView.isHidden = genres.isEmpty && tags.isEmpty
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if abs(bounds.width - lastMeasuredWidth) > .ulpOfOne {
            shouldUpdateTagCollectionHeight = true
        }
        updateTagCollectionHeightIfNeeded()
    }

    private func updateTagCollectionHeightIfNeeded() {
        guard shouldUpdateTagCollectionHeight else { return }

        let hasTags = !tags.isEmpty
        tagsCollectionTopConstraint?.update(offset: hasTags ? Layout.tagTopSpacing : 0)

        guard hasTags else {
            tagsCollectionHeightConstraint?.update(offset: 0)
            lastMeasuredWidth = bounds.width
            shouldUpdateTagCollectionHeight = false
            return
        }

        guard bounds.width > 0 else { return }

        tagsCollectionView.collectionViewLayout.invalidateLayout()
        tagsCollectionView.layoutIfNeeded()

        let contentHeight = ceil(tagsCollectionView.collectionViewLayout.collectionViewContentSize.height)
        tagsCollectionHeightConstraint?.update(offset: max(contentHeight, 1))
        lastMeasuredWidth = bounds.width
        shouldUpdateTagCollectionHeight = false
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        genreLabel.text = nil
        tags.removeAll()
        tagsCollectionView.reloadData()
        contentView.isHidden = false
        shouldUpdateTagCollectionHeight = false
        lastMeasuredWidth = 0
        tagsCollectionTopConstraint?.update(offset: Layout.tagTopSpacing)
        tagsCollectionHeightConstraint?.update(offset: 0)
    }
}

// MARK: - UICollectionViewDataSource
extension GenreAndTagsCollectionViewCell: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tags.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: TagCell.identifier,
            for: indexPath
        ) as? TagCell else {
            return UICollectionViewCell()
        }

        cell.configure(with: tags[indexPath.item].name)
        return cell
    }
}

// MARK: - Tag Cell
final class TagCell: UICollectionViewCell {

    private let containerView = {
        let view = UIView()
        view.backgroundColor = .systemGray5
        view.layer.cornerRadius = 12
        return view
    }()

    private let label = {
        let label = UILabel()
        label.font = .Body.regular12
        label.textColor = .label
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(containerView)
        containerView.addSubview(label)

        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        label.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(12)
            make.top.bottom.equalToSuperview().inset(6)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with text: String) {
        label.text = "#\(text)"
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        label.text = nil
    }
}
