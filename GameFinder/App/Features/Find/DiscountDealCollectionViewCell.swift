//
//  DiscountDealCollectionViewCell.swift
//  GameFinder
//
//  Created by Codex on 2/28/26.
//

import UIKit
import SnapKit
import Kingfisher

// MARK: - TrapezoidBadgeLabel
private final class TrapezoidBadgeLabel: UIView {

    private let label: UILabel = {
        let label = UILabel()
        label.font = .NanumBarunGothic.bold12
        label.textColor = .systemBackground
        label.textAlignment = .center
        return label
    }()

    private let shapeLayer = CAShapeLayer()

    /// 오른쪽 사선 기울기 (포인트)
    private let slantOffset: CGFloat = 8

    var text: String? {
        get { label.text }
        set {
            label.text = newValue
            invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        layer.insertSublayer(shapeLayer, at: 0)
        shapeLayer.fillColor = UIColor.systemRed.cgColor
        addSubview(label)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        let labelSize = label.intrinsicContentSize
        let width = labelSize.width + 8 + slantOffset
        let height = max(labelSize.height + 4, 18)
        return CGSize(width: width, height: height)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let w = bounds.width
        let h = bounds.height
        guard w > 0, h > 0 else { return }

        // 사다리꼴: 왼쪽은 직각, 오른쪽은 사선
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: w, y: 0))
        path.addLine(to: CGPoint(x: w - slantOffset, y: h))
        path.addLine(to: CGPoint(x: 0, y: h))
        path.close()

        shapeLayer.path = path.cgPath

        let labelInset = (slantOffset / 2) - 2
        label.frame = CGRect(x: labelInset, y: 0,
                             width: w - slantOffset, height: h)
    }
}

// MARK: - DiscountDealCollectionViewCell
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
        label.font = .Title.bold14
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

    private let savingsBadge = TrapezoidBadgeLabel()

    private lazy var bottomStack = {
        let stackView = UIStackView(arrangedSubviews: [savingsBadge, salePriceLabel, normalPriceLabel])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 5
        stackView.setCustomSpacing(3, after: savingsBadge)
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
            make.trailing.lessThanOrEqualToSuperview().offset(-16)
            make.bottom.lessThanOrEqualToSuperview().offset(-12)
        }

        savingsBadge.snp.makeConstraints { make in
            make.height.equalTo(18)
        }
    }

    override func configureView() {
        super.configureView()
        backgroundColor = .clear
    }

    func configure(with deal: DiscountDeal) {
        titleLabel.text = deal.title
        storeLabel.text = deal.displayStoreName
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

        savingsBadge.text = "\(deal.displaySavingsPercent)%"

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
