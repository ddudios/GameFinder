//
//  PlatformCardCell.swift
//  GameFinder
//
//  Created by Suji Jang on 10/9/25.
//

import UIKit
import SnapKit

final class PlatformCardCell: UICollectionViewCell {

    // MARK: - UI Components
    private let backgroundImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        return imageView
    }()

    private let overlayView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        view.layer.cornerRadius = 12
        return view
    }()

    private let titleLabel = {
        let label = UILabel()
        label.font = .Title.bold24
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupUI() {
        contentView.addSubview(backgroundImageView)
        contentView.addSubview(overlayView)
        contentView.addSubview(titleLabel)

        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        overlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.horizontalEdges.equalToSuperview().inset(16)
        }

        // 그림자 효과
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOpacity = 0.2
        contentView.layer.shadowOffset = CGSize(width: 0, height: 2)
        contentView.layer.shadowRadius = 8
    }

    // MARK: - Configuration
    func configure(with platform: String) {
        titleLabel.text = platform
        backgroundImageView.image = UIImage(named: platform) ?? UIImage(named: "noImage")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        backgroundImageView.image = nil
    }
}
