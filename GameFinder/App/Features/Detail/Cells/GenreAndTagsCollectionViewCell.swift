//
//  GenreAndTagsCollectionViewCell.swift
//  GameFinder
//
//  Created by Suji Jang on 10/5/25.
//

import UIKit
import SnapKit

final class GenreAndTagsCollectionViewCell: BaseCollectionViewCell {

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

    private lazy var tagsCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        layout.minimumInteritemSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.register(TagCell.self, forCellWithReuseIdentifier: TagCell.identifier)
        return collectionView
    }()

    private var tags: [GameTag] = []

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
            make.top.equalTo(genreLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(36).priority(.high)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // 태그가 없을 때 높이를 0으로 만들어 공간 제거
        if tagsCollectionView.isHidden {
            tagsCollectionView.snp.updateConstraints { make in
                make.height.equalTo(0).priority(.required)
            }
        } else {
            tagsCollectionView.snp.updateConstraints { make in
                make.height.equalTo(36).priority(.high)
            }
        }
    }

    func configure(genres: [GameGenre], tags: [GameTag]) {
        let genreNames = genres.map { $0.name }
        genreLabel.text = genreNames.joined(separator: ", ")

        self.tags = tags
        tagsCollectionView.reloadData()

        // 태그가 없으면 태그 컬렉션뷰 숨김
        tagsCollectionView.isHidden = tags.isEmpty

        // 장르와 태그가 모두 없으면 전체 숨김
        contentView.isHidden = genres.isEmpty && tags.isEmpty
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        genreLabel.text = nil
        tags.removeAll()
        tagsCollectionView.reloadData()
        tagsCollectionView.isHidden = false
        contentView.isHidden = false
    }
}

// MARK: - UICollectionViewDataSource
extension GenreAndTagsCollectionViewCell: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return min(tags.count, 10) // 최대 10개
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
