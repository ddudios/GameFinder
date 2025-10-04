//
//  FinderCollectionViewCell.swift
//  GameFinder
//
//  Created by Suji Jang on 9/30/25.
//

import UIKit
import SnapKit
import RxSwift

final class FinderCollectionViewCell: BaseCollectionViewCell {
    
    let classImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = .black
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = Radius.card
        imageView.isUserInteractionEnabled = true
        imageView.clipsToBounds = true
        return imageView
    }()
    
    let likeButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "likeButton_fill"), for: .normal)
        button.backgroundColor = .clear
        return button
    }()
    
    private let titleLabel = TitleLabel(text: "Grand Theft Auto V: Story Mode")
    
    private let descriptionLabel = {
        let label = UILabel()
        label.font = .Prominent.semibold12
        label.text = "Shooter, Arcade"
        label.textAlignment = .left
        return label
    }()
    
    let priceLabel = {
        let label = UILabel()
        label.font = .Prominent.bold15
        let attributeString = NSMutableAttributedString(string: "1,000,000원")
        attributeString.addAttributes([
            .strikethroughStyle: NSUnderlineStyle.single.rawValue,
            .strikethroughColor: UIColor.systemGray2
        ], range: NSMakeRange(0, attributeString.length))
        label.attributedText = attributeString
        return label
    }()
    
    let salePriceLabel = {
        let label = UILabel()
        label.text = "100,000원"
        label.textColor = .label
        label.font = .Prominent.bold15
        return label
    }()
    
    let rateLabel = {
        let label = UILabel()
        label.font = .Prominent.bold15
        label.text = "90%"
        return label
    }()
    
    private lazy var priceStackView = {
        let stackView = UIStackView(arrangedSubviews: [priceLabel, salePriceLabel, rateLabel])
        stackView.axis = .horizontal
        stackView.spacing = Spacing.xxs
        return stackView
    }()
    
    var disposeBag = DisposeBag()

    override func prepareForReuse() {
        priceLabel.isHidden = false
        salePriceLabel.isHidden = false
        disposeBag = DisposeBag()
    }
    
    func setData(title: String, categoryTitle: String, description: String) {
        titleLabel.text = title
        descriptionLabel.text = description
    }
    
    override func configureHierarchy() {
        contentView.addSubview(classImageView)
        classImageView.addSubview(likeButton)
        contentView.addSubview(titleLabel)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(priceStackView)
    }
    
    override func configureLayout() {
        classImageView.snp.makeConstraints { make in
            make.top.equalTo(contentView.snp.top).offset(Spacing.m)
            make.horizontalEdges.equalTo(contentView.snp.horizontalEdges).inset(Spacing.m)
            make.height.equalTo(180)
        }
        
        likeButton.snp.makeConstraints { make in
            make.size.equalTo(50)
            make.top.equalTo(classImageView.snp.top)
            make.trailing.equalTo(classImageView.snp.trailing)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(classImageView.snp.bottom).offset(Spacing.m)
            make.leading.equalTo(classImageView.snp.leading)
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(Spacing.m)
            make.horizontalEdges.equalTo(classImageView.snp.horizontalEdges)
        }
        
        priceStackView.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(Spacing.m)
            make.leading.equalTo(classImageView.snp.leading)
        }
    }
}
