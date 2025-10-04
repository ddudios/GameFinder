//
//  ScreenshotCollectionViewCell.swift
//  GameFinder
//
//  Created by Suji Jang on 10/5/25.
//

import UIKit
import SnapKit
import Kingfisher

final class ScreenshotCollectionViewCell: BaseCollectionViewCell {

    private let imageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray5
        return imageView
    }()

    override func configureHierarchy() {
        contentView.addSubview(imageView)
    }

    override func configureLayout() {
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func configure(with imageUrl: String) {
        guard let url = URL(string: imageUrl) else {
            imageView.image = UIImage(named: "noImage")
            imageView.hideSkeleton()
            return
        }

        imageView.showSkeleton()
        imageView.kf.setImage(
            with: url,
            placeholder: UIImage(named: "noImage"),
            options: [
                .transition(.fade(0.2)),
                .cacheOriginalImage
            ],
            completionHandler: { [weak self] _ in
                self?.imageView.hideSkeleton()
            }
        )
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.kf.cancelDownloadTask()
        imageView.image = nil
        imageView.hideSkeleton()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.updateSkeletonFrame()
    }
}
