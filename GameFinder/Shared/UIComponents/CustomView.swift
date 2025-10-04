//
//  CustomView.swift
//  GameFinder
//
//  Created by Suji Jang on 9/30/25.
//

import UIKit
import SnapKit

final class BadgeView: UIView {
    
    private let icon = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(systemName: "star.fill")
        imageView.tintColor = .systemOrange
        return imageView
    }()
    private let textLabel = {
        let label = UILabel()
        label.font = .NanumBarunGothic.bold12
        label.textColor = .white
        return label
    }()
    
    init() {
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = self.frame.height / Radius.circle
    }
    
    private func setupUI() {
        // 배경 블러 (반투명)
        let blurEffect = UIBlurEffect(style: .systemThinMaterialDark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurView.alpha = 0.8 // 반투명 블러
        insertSubview(blurView, at: 0)

        // 블러 뷰에 frame 설정
        blurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        let stackView = UIStackView(arrangedSubviews: [icon, textLabel])
        stackView.axis = .horizontal
        stackView.spacing = Spacing.xxxs
        stackView.alignment = .center

        addSubview(stackView)
        icon.snp.makeConstraints { make in
            make.size.equalTo(Size.xs)
        }
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8)
        }

        backgroundColor = UIColor.black.withAlphaComponent(0.5) // 더 투명하게
        clipsToBounds = true
    }
    
    func configure(text: String) {
        textLabel.text = text
    }

    func configure(rating: Double) {
        textLabel.text = String(format: "%.1f", rating)
    }
}

final class SectionHeaderView: UICollectionReusableView {
    private let label = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        label.textAlignment = .center
        label.textColor = .systemGray
        label.numberOfLines = 2
        label.font = .Chosun.regular16
        
        addSubview(label)
        label.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview().inset(100)
            $0.centerY.equalToSuperview()
        }
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(with text: String) {
        label.text = text
    }
}
