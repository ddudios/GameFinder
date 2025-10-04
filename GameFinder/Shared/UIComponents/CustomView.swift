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
        label.font = .NanumBarunGothic.regular12
        label.textColor = .label
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
        let blurEffect = UIBlurEffect(style: .systemThinMaterialDark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurView.alpha = 0.7
        insertSubview(blurView, at: 0)

        blurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        let stackView = UIStackView(arrangedSubviews: [icon, textLabel])
        stackView.axis = .horizontal
        stackView.spacing = Spacing.xxs
        stackView.alignment = .center

        addSubview(stackView)
        icon.snp.makeConstraints { make in
            make.size.equalTo(Size.xs)
        }
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8)
        }

        backgroundColor = UIColor.black.withAlphaComponent(0.5)
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
    private let chevronImageView = UIImageView()
    var onTap: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        label.textAlignment = .center
        label.textColor = .white
        label.numberOfLines = 1
        label.font = .Chosun.regular16

        chevronImageView.image = UIImage(systemName: "chevron.right")
        chevronImageView.tintColor = .systemGray
        chevronImageView.contentMode = .scaleAspectFit

        addSubview(label)
        addSubview(chevronImageView)

        label.snp.makeConstraints {
            $0.center.equalToSuperview()
        }

        chevronImageView.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(20)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(20)
        }

        // 탭 제스처 추가
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
        isUserInteractionEnabled = true
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(with text: String) {
        label.text = text
    }

    @objc private func handleTap() {
        onTap?()
    }
}
