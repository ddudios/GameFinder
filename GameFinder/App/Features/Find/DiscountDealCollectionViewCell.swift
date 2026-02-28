//
//  DiscountDealCollectionViewCell.swift
//  GameFinder
//
//  Created by Codex on 2/28/26.
//

import UIKit
import SnapKit
import Kingfisher

final class DiscountDealCollectionViewCell: BaseCollectionViewCell {

    private let thumbnailImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = .systemGray5
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 16
        imageView.clipsToBounds = true
        return imageView
    }()

    private let titleLabel = {
        let label = UILabel()
        label.font = .Title.bold16
        label.textColor = .label
        label.numberOfLines = 2
        return label
    }()

    private let storeLabel = {
        let label = UILabel()
        label.font = .Body.regular12
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        return label
    }()

    private let salePriceLabel = {
        let label = UILabel()
        label.font = .Title.bold16
        label.textColor = .systemRed
        label.numberOfLines = 1
        return label
    }()

    private let normalPriceLabel = {
        let label = UILabel()
        label.font = .Body.regular12
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        return label
    }()

    private let savingsBadge = {
        let label = UILabel()
        label.font = .NanumBarunGothic.bold12
        label.textColor = .systemBackground
        label.textAlignment = .center
        label.backgroundColor = .systemRed
        label.layer.cornerRadius = 10
        label.clipsToBounds = true
        return label
    }()

    private lazy var bottomStack = {
        let stackView = UIStackView(arrangedSubviews: [salePriceLabel, normalPriceLabel])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 8
        return stackView
    }()

    private lazy var textStack = {
        let stackView = UIStackView(arrangedSubviews: [titleLabel, storeLabel, bottomStack])
        stackView.axis = .vertical
        stackView.spacing = 6
        stackView.alignment = .leading
        return stackView
    }()

    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailImageView.kf.cancelDownloadTask()
        thumbnailImageView.image = nil
        titleLabel.text = nil
        storeLabel.text = nil
        salePriceLabel.text = nil
        normalPriceLabel.text = nil
        savingsBadge.text = nil
    }

    override func configureHierarchy() {
        contentView.addSubview(thumbnailImageView)
        contentView.addSubview(textStack)
        contentView.addSubview(savingsBadge)
    }

    override func configureLayout() {
        thumbnailImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 80, height: 80))
        }

        textStack.snp.makeConstraints { make in
            make.leading.equalTo(thumbnailImageView.snp.trailing).offset(12)
            make.top.equalToSuperview().offset(12)
            make.trailing.lessThanOrEqualTo(savingsBadge.snp.leading).offset(-8)
            make.bottom.lessThanOrEqualToSuperview().offset(-12)
        }

        savingsBadge.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.width.greaterThanOrEqualTo(56)
            make.height.equalTo(24)
        }
    }

    override func configureView() {
        super.configureView()
        backgroundColor = .clear
    }

    func configure(with deal: DiscountDeal) {
        titleLabel.text = deal.title
        storeLabel.text = "Store \(deal.storeID)"
        salePriceLabel.text = Self.currencyFormatter.string(from: NSNumber(value: deal.salePrice)) ?? "$\(deal.salePrice)"

        let normalPriceText = Self.currencyFormatter.string(from: NSNumber(value: deal.normalPrice)) ?? "$\(deal.normalPrice)"
        let attributed = NSAttributedString(
            string: normalPriceText,
            attributes: [
                .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                .foregroundColor: UIColor.secondaryLabel
            ]
        )
        normalPriceLabel.attributedText = attributed

        let roundedSaving = Int(deal.savingsPercent.rounded())
        savingsBadge.text = "  -\(roundedSaving)%  "

        if let thumbURL = deal.thumbURL,
           let url = URL(string: thumbURL) {
            thumbnailImageView.kf.setImage(
                with: url,
                placeholder: UIImage(named: "noImage"),
                options: [
                    .transition(.fade(0.2)),
                    .cacheOriginalImage
                ]
            )
        } else {
            thumbnailImageView.image = UIImage(named: "noImage")
        }
    }

    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        return formatter
    }()
}
