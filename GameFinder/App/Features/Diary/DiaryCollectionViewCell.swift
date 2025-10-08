//
//  DiaryCollectionViewCell.swift
//  GameFinder
//
//  Created by Claude on 10/6/25.
//

import UIKit
import SnapKit
import AVFoundation

final class DiaryCollectionViewCell: BaseCollectionViewCell {

    private let cardView = {
        let view = UIView()
        view.backgroundColor = .label
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.1
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        return view
    }()

    private let monthLabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .systemBackground
        label.textAlignment = .center
        return label
    }()

    private let yearLabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .systemBackground
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

    private let titleLabel = {
        let label = UILabel()
        label.font = .Title.bold16
        label.textColor = .systemBackground
        label.numberOfLines = 1
        return label
    }()

    private let contentLabel = {
        let label = UILabel()
        label.font = .Body.regular14
        label.textColor = .systemBackground
        label.numberOfLines = 3
        return label
    }()

    private lazy var textStackView = {
        let stackView = UIStackView(arrangedSubviews: [titleLabel, contentLabel])
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.alignment = .leading
        return stackView
    }()

    private let mediaImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray5
        return imageView
    }()

    private let mediaContainerView = {
        let view = UIView()
        view.clipsToBounds = true
        return view
    }()

    private let playIconImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "play.circle.fill")
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        return imageView
    }()

    override func prepareForReuse() {
        super.prepareForReuse()
        monthLabel.text = nil
        yearLabel.text = nil
        titleLabel.text = nil
        contentLabel.text = nil
        mediaImageView.image = nil
        playIconImageView.isHidden = true
    }

    func configure(with diary: RealmDiary) {
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMM"
        let monthString = monthFormatter.string(from: diary.createdAt).uppercased()
        monthLabel.text = String(monthString.prefix(3))

        let yearFormatter = DateFormatter()
        yearFormatter.dateFormat = "yyyy"
        yearLabel.text = yearFormatter.string(from: diary.createdAt)

        titleLabel.text = diary.title
        contentLabel.text = diary.content

        // 미디어 처리 (첫 번째 미디어만 표시)
        if let firstMedia = diary.mediaItems.first,
           let mediaData = DiaryManager.shared.loadMediaFromDisk(relativePath: firstMedia.filePath) {

            if firstMedia.type == "video" {
                // 동영상 썸네일 생성
                if let thumbnail = generateVideoThumbnail(from: mediaData) {
                    mediaImageView.image = thumbnail
                    playIconImageView.isHidden = false
                }
            } else if firstMedia.type == "image" {
                // 이미지 표시
                mediaImageView.image = UIImage(data: mediaData)
                playIconImageView.isHidden = true
            }
            textStackView.isHidden = true
            mediaImageView.isHidden = false
        } else {
            // 미디어 없을 때 텍스트 표시
            textStackView.isHidden = false
            mediaImageView.isHidden = true
            playIconImageView.isHidden = true
        }
    }

    private func generateVideoThumbnail(from videoData: Data) -> UIImage? {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mov")
        do {
            try videoData.write(to: tempURL)
            let asset = AVAsset(url: tempURL)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true

            let cgImage = try imageGenerator.copyCGImage(at: .zero, actualTime: nil)
            try? FileManager.default.removeItem(at: tempURL)
            return UIImage(cgImage: cgImage)
        } catch {
            try? FileManager.default.removeItem(at: tempURL)
            return nil
        }
    }

    override func configureHierarchy() {
        contentView.addSubview(cardView)
        cardView.addSubview(dateStackView)
        cardView.addSubview(textStackView)
        cardView.addSubview(mediaContainerView)
        mediaContainerView.addSubview(mediaImageView)
        mediaImageView.addSubview(playIconImageView)
    }

    override func configureLayout() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        cardView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0))
        }

        dateStackView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.equalTo(60)
        }

        textStackView.snp.makeConstraints { make in
            make.leading.equalTo(dateStackView.snp.trailing).offset(16)
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }

        mediaContainerView.snp.makeConstraints { make in
            make.leading.equalTo(dateStackView.snp.trailing).offset(16)
            make.trailing.top.bottom.equalToSuperview()
        }

        mediaImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        playIconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(48)
        }

        // mediaContainerView의 오른쪽 모서리만 둥글게
        mediaContainerView.layer.cornerRadius = 12
        mediaContainerView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
    }
}
