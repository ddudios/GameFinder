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

    // MARK: - Properties
    private var currentGameId: Int?
    var onDeleteButtonTapped: ((Int) -> Void)?

    // MARK: - UI Components
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

    private let deleteButton = {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "bookmark.fill")
        config.baseForegroundColor = .Signature
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)

        let imageConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        config.preferredSymbolConfigurationForImage = imageConfig

        button.configuration = config
        return button
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

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        backgroundImageView.kf.cancelDownloadTask()
        backgroundImageView.image = nil
        gameTitleLabel.text = nil
        monthLabel.text = nil
        yearLabel.text = nil
        currentGameId = nil
    }

    // MARK: - Actions
    @objc private func deleteButtonTapped() {
        guard let gameId = currentGameId else { return }
        onDeleteButtonTapped?(gameId)
    }

    // MARK: - Configuration
    func configure(with game: Game, lastUpdatedDate: Date?) {
        currentGameId = game.id
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
        contentView.addSubview(deleteButton)
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

        deleteButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().inset(12)
        }

        gameTitleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(16)
        }
    }
}
