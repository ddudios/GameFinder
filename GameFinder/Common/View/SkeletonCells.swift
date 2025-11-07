//
//  SkeletonCells.swift
//  GameFinder
//
//  Created by Suji Jang on 10/10/25.
//

import UIKit
import SnapKit

// MARK: - Card Skeleton Cell
final class CardSkeletonCell: UICollectionViewCell {

    private let imageSkeletonView = SkeletonView()
    private let titleSkeletonView = SkeletonView()
    private let subtitleSkeletonView = SkeletonView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(imageSkeletonView)
        contentView.addSubview(titleSkeletonView)
        contentView.addSubview(subtitleSkeletonView)

        imageSkeletonView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        titleSkeletonView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(60)
            make.height.equalTo(24)
        }

        subtitleSkeletonView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(28)
            make.height.equalTo(20)
        }

        imageSkeletonView.startAnimating()
        titleSkeletonView.startAnimating()
        subtitleSkeletonView.startAnimating()
    }
}

// MARK: - List Skeleton Cell
final class ListSkeletonCell: UICollectionViewCell {

    private let imageSkeletonView = SkeletonView()
    private let titleSkeletonView = SkeletonView()
    private let subtitleSkeletonView = SkeletonView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(imageSkeletonView)
        contentView.addSubview(titleSkeletonView)
        contentView.addSubview(subtitleSkeletonView)

        imageSkeletonView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(80)
        }

        titleSkeletonView.snp.makeConstraints { make in
            make.leading.equalTo(imageSkeletonView.snp.trailing).offset(12)
            make.trailing.equalToSuperview().inset(16)
            make.top.equalToSuperview().offset(20)
            make.height.equalTo(20)
        }

        subtitleSkeletonView.snp.makeConstraints { make in
            make.leading.equalTo(imageSkeletonView.snp.trailing).offset(12)
            make.trailing.equalToSuperview().inset(60)
            make.top.equalTo(titleSkeletonView.snp.bottom).offset(8)
            make.height.equalTo(16)
        }

        imageSkeletonView.startAnimating()
        titleSkeletonView.startAnimating()
        subtitleSkeletonView.startAnimating()
    }
}

// MARK: - Free Game Skeleton Cell
final class FreeGameSkeletonCell: UICollectionViewCell {

    private let imageSkeletonView = SkeletonView()
    private let titleSkeletonView = SkeletonView()
    private let subtitleSkeletonView = SkeletonView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(imageSkeletonView)
        contentView.addSubview(titleSkeletonView)
        contentView.addSubview(subtitleSkeletonView)

        imageSkeletonView.layer.cornerRadius = 12
        imageSkeletonView.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.size.equalTo(60)
        }

        titleSkeletonView.snp.makeConstraints { make in
            make.leading.equalTo(imageSkeletonView.snp.trailing).offset(12)
            make.trailing.equalToSuperview().inset(60)
            make.top.equalToSuperview().offset(24)
            make.height.equalTo(18)
        }

        subtitleSkeletonView.snp.makeConstraints { make in
            make.leading.equalTo(imageSkeletonView.snp.trailing).offset(12)
            make.trailing.equalToSuperview().inset(80)
            make.top.equalTo(titleSkeletonView.snp.bottom).offset(8)
            make.height.equalTo(14)
        }

        imageSkeletonView.startAnimating()
        titleSkeletonView.startAnimating()
        subtitleSkeletonView.startAnimating()
    }
}
