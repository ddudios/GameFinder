//
//  FeaturedGameCell.swift
//  GameFinder
//
//  Created by Suji Jang on 9/30/25.
//

import UIKit
import SnapKit
import Kingfisher

final class FeaturedGameCell: BaseCollectionViewCell {
    
    // MARK: - UI Components
    private let imageContainerView = {
        let view = UIView()
        view.layer.cornerRadius = 28
        view.clipsToBounds = true
        return view
    }()
    
    private let imageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray5
        return imageView
    }()
    
    private let gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.6).cgColor
        ]
        layer.locations = [0.6, 1.0]
        return layer
    }()
    
    private let badgeView = BadgeView()
    
    private let titleLabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textColor = .white
        label.numberOfLines = 2
        return label
    }()
    
    private let ratingLabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .systemYellow
        return label
    }()
    
    private let genreLabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .white.withAlphaComponent(0.7)
        return label
    }()
    
    private let loadingIndicator = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.color = .white
        return indicator
    }()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGradient(for: frame.size)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.kf.cancelDownloadTask()
        imageView.image = nil
        titleLabel.text = nil
        ratingLabel.text = nil
        genreLabel.text = nil
    }
    
    // MARK: - Layout
    override func configureHierarchy() {
        contentView.addSubview(imageContainerView)
        imageContainerView.addSubview(imageView)
        imageView.layer.addSublayer(gradientLayer)
        imageContainerView.addSubview(badgeView)
        imageContainerView.addSubview(loadingIndicator)
        contentView.addSubview(titleLabel)
        contentView.addSubview(ratingLabel)
        contentView.addSubview(genreLabel)
    }
    
    override func configureLayout() {
        imageContainerView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(imageContainerView.snp.width).multipliedBy(1.2)
        }
        
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        badgeView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(16)
        }
        
        loadingIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.top.equalTo(imageContainerView.snp.bottom).offset(16)
        }
        
        ratingLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
        }
        
        genreLabel.snp.makeConstraints { make in
            make.leading.equalTo(ratingLabel.snp.trailing).offset(12)
            make.centerY.equalTo(ratingLabel)
            make.trailing.lessThanOrEqualToSuperview().inset(20)
            make.bottom.lessThanOrEqualToSuperview().inset(12)
        }
        
        // 그림자
        imageContainerView.layer.shadowColor = UIColor.black.cgColor
        imageContainerView.layer.shadowOpacity = 0.3
        imageContainerView.layer.shadowOffset = CGSize(width: 0, height: 8)
        imageContainerView.layer.shadowRadius = 16
        
        layer.masksToBounds = false
        contentView.layer.masksToBounds = false
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if gradientLayer.frame.size != imageContainerView.bounds.size {
            setupGradient(for: imageContainerView.bounds.size)
        }
    }
    
    private func setupGradient(for size: CGSize) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradientLayer.frame = CGRect(origin: .zero, size: size)
        CATransaction.commit()
    }
    
    // MARK: - Configuration
    func configure(with game: Game) {
        titleLabel.text = game.name
        ratingLabel.text = "⭐️ \(String(format: "%.1f", game.rating))"
        
        // 장르 표시
        let genreNames = game.genres.map { $0.name }
        genreLabel.text = genreNames.prefix(2).joined(separator: " • ")
        
        // 이미지 로딩
        imageView.image = nil
        
        guard let backgroundImageString = game.backgroundImage,
              let imageURL = URL(string: backgroundImageString) else {
            print("이미지 URL 없음: \(game.name)")
            imageView.backgroundColor = .systemGray5
            return
        }
        loadingIndicator.startAnimating()
        
        imageView.kf.setImage(
            with: imageURL,
            options: [
                .transition(.fade(0.2)),
                .cacheOriginalImage
            ],
            completionHandler: { [weak self] result in
                self?.loadingIndicator.stopAnimating()
            }
        )
    }
}
