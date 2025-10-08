//
//  GameDiaryListCollectionViewCell.swift
//  GameFinder
//
//  Created by Claude on 10/6/25.
//

import UIKit
import SnapKit
import Kingfisher

final class GameDiaryListCollectionViewCell: BaseCollectionViewCell {

    private let backgroundImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()

    private let overlayView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.5)
        return view
    }()

    private let monthLabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        return label
    }()

    private let yearLabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center
        return label
    }()

    private lazy var dateStackView = {
        let stackView = UIStackView(arrangedSubviews: [monthLabel, yearLabel])
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.alignment = .center
        return stackView
    }()

    private let gameTitleLabel = {
        let label = UILabel()
        label.font = .Title.bold16
        label.numberOfLines = 2
        return label
    }()

    override func prepareForReuse() {
        super.prepareForReuse()
        backgroundImageView.kf.cancelDownloadTask()
        backgroundImageView.image = nil
        gameTitleLabel.text = nil
        monthLabel.text = nil
        yearLabel.text = nil
    }

    func configure(with game: Game, lastUpdatedDate: Date?) {
        gameTitleLabel.text = game.name

        // 날짜 포맷 설정
        if let date = lastUpdatedDate {
            let monthFormatter = DateFormatter()
            monthFormatter.dateFormat = "MMM"
            monthLabel.text = monthFormatter.string(from: date).uppercased()

            let yearFormatter = DateFormatter()
            yearFormatter.dateFormat = "yyyy"
            yearLabel.text = yearFormatter.string(from: date)
        } else {
            monthLabel.text = "NEW"
            yearLabel.text = ""
        }

        // backgroundImage가 있을 때
        if let backgroundImageString = game.backgroundImage,
           !backgroundImageString.isEmpty,
           let imageURL = URL(string: backgroundImageString) {
            backgroundImageView.kf.setImage(
                with: imageURL,
                placeholder: UIImage(named: "noImage"),
                options: [
                    .transition(.fade(0.2)),
                    .cacheOriginalImage
                ]
            )
            overlayView.isHidden = false
            contentView.backgroundColor = .clear

            // 텍스트 색상: label 컬러
            gameTitleLabel.textColor = .label
            monthLabel.textColor = .label
            yearLabel.textColor = .label
        } else {
            // backgroundImage가 없을 때
            backgroundImageView.image = nil
            overlayView.isHidden = true
            contentView.backgroundColor = .label

            // 텍스트 색상: systemBackground 컬러
            gameTitleLabel.textColor = .systemBackground
            monthLabel.textColor = .systemBackground
            yearLabel.textColor = .systemBackground
        }
    }

    override func configureHierarchy() {
        contentView.addSubview(backgroundImageView)
        contentView.addSubview(overlayView)
        contentView.addSubview(dateStackView)
        contentView.addSubview(gameTitleLabel)
    }

    override func configureLayout() {
        contentView.layer.cornerRadius = 12
        contentView.clipsToBounds = true

        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        overlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        dateStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.equalToSuperview().offset(16)
        }

        gameTitleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(16)
        }
    }
}
