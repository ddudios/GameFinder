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
        imageView.tintColor = .Signature
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

        backgroundColor = UIColor.systemBackground.withAlphaComponent(0.5)
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
        label.textColor = .label
        label.numberOfLines = 1
        label.font = .Chosun.regular16

        chevronImageView.image = UIImage(systemName: "chevron.right")
        chevronImageView.tintColor = .secondaryLabel
        chevronImageView.contentMode = .scaleAspectFit

        addSubview(label)
        addSubview(chevronImageView)

        chevronImageView.snp.makeConstraints {
            $0.size.equalTo(20)
        }

        // 탭 제스처 추가
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
        isUserInteractionEnabled = true
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(with text: String, alignment: NSTextAlignment = .center) {
        label.text = text

        // 기존 제약조건 제거
        label.snp.removeConstraints()
        chevronImageView.snp.removeConstraints()

        chevronImageView.snp.makeConstraints {
            $0.size.equalTo(20)
            $0.centerY.equalToSuperview()
        }

        if alignment == .center {
            // center 정렬: label을 중앙에, chevron을 label 오른쪽에
            label.snp.makeConstraints {
                $0.centerX.equalToSuperview()
                $0.centerY.equalToSuperview()
            }
            chevronImageView.snp.makeConstraints {
                $0.leading.equalTo(label.snp.trailing).offset(8)
            }
        } else {
            // left 정렬: label을 왼쪽에, chevron을 label 오른쪽에
            label.snp.makeConstraints {
                $0.leading.equalToSuperview().inset(20)
                $0.centerY.equalToSuperview()
            }
            chevronImageView.snp.makeConstraints {
                $0.leading.equalTo(label.snp.trailing).offset(8)
            }
        }
    }

    @objc private func handleTap() {
        onTap?()
    }
}
