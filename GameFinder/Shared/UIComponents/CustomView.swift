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
        // 배경 블러
        let blurEffect = UIBlurEffect(style: .systemThinMaterialDark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        insertSubview(blurView, at: 0)
        
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
        
        backgroundColor = UIColor.black.withAlphaComponent(0.7)
        clipsToBounds = true
    }
    
    func configure(text: String) {
        textLabel.text = text
    }
}

final class FeaturedHeaderView: UICollectionReusableView {
    static let kind = "FeaturedHeaderView"
    private let label = UILabel()
    override init(frame: CGRect) {
        super.init(frame: frame)
        label.text = "DAILY CHALLENGE\nFOR EVERYONE"
        label.textAlignment = .center
        label.textColor = UIColor.secondaryLabel
        label.numberOfLines = 2
        label.font = .systemFont(ofSize: 13, weight: .medium)
        addSubview(label)
        label.snp.makeConstraints { $0.edges.equalToSuperview() }
    }
    required init?(coder: NSCoder) { fatalError() }
}

final class FeaturedPageControlView: UICollectionReusableView {
    static let kind = "FeaturedPageControlView"
    let pageControl = UIPageControl()
    override init(frame: CGRect) {
        super.init(frame: frame)
        pageControl.hidesForSinglePage = true
        addSubview(pageControl)
        pageControl.snp.makeConstraints { $0.center.equalToSuperview() }
    }
    required init?(coder: NSCoder) { fatalError() }
}
