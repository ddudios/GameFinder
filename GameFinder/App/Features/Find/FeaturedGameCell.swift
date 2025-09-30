//
//  FeaturedCell.swift
//  GameFinder
//
//  Created by Suji Jang on 9/30/25.
//

import UIKit
import SnapKit

final class FeaturedGameCell: BaseCollectionViewCell {
    
    private let imageContainerView = {
        let view = UIView() // 이미지 컨테이너 추가
        view.layer.cornerRadius = 28
        view.clipsToBounds = true
        return view
    }()
    private let imageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    private let gradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.6).cgColor // 투명도
        ]
        layer.locations = [0.6, 1.0]
        return layer
    }()
    private let badgeView = BadgeView()
    private let titleLabel = {
        let label = UILabel()
        // 타이틀 - 이미지 밖으로
        label.font = .systemFont(ofSize: 32, weight: .bold) // 크기 증가
        label.textColor = .white
        label.numberOfLines = 2
        return label
    }()
    private let dateLabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .white.withAlphaComponent(0.7)
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGradient(for: frame.size)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func configureHierarchy() {
        contentView.addSubview(imageContainerView)
        imageContainerView.addSubview(imageView)
        imageView.layer.addSublayer(gradientLayer)
        imageContainerView.addSubview(badgeView)
        contentView.addSubview(titleLabel) // contentView에 직접 추가
        contentView.addSubview(dateLabel)
    }
    
    override func configureLayout() {
        imageContainerView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(imageContainerView.snp.width).multipliedBy(1.2) // 세로로 더 긴 비율
        }
        
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        badgeView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(16)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.trailing.equalToSuperview().inset(20)
            make.top.equalTo(imageContainerView.snp.bottom).offset(16)
        }
        
        dateLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.bottom.lessThanOrEqualToSuperview().inset(12)
        }
        
        // 그림자 - imageContainerView에 적용
        imageContainerView.layer.shadowColor = UIColor.black.cgColor
        imageContainerView.layer.shadowOpacity = 0.3
        imageContainerView.layer.shadowOffset = CGSize(width: 0, height: 8)
        imageContainerView.layer.shadowRadius = 16
        
        // 그림자가 보이도록
        layer.masksToBounds = false
        contentView.layer.masksToBounds = false
    }
    
    private func setupGradient(for size: CGSize) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradientLayer.frame = CGRect(origin: .zero, size: size)
        CATransaction.commit()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if gradientLayer.frame.size != imageContainerView.bounds.size {
            setupGradient(for: imageContainerView.bounds.size)
        }
    }
    
    func configure(with game: Basic) {
        layoutIfNeeded()
        setupGradient(for: imageContainerView.bounds.size)
        
        titleLabel.text = game.name
        titleLabel.textColor = .blue
        dateLabel.text = "Thursday"
        badgeView.configure(text: "4.8")
        
        imageView.backgroundColor = .darkGray
    }
}
