//
//  SectionHeaderView.swift
//  GameFinder
//
//  Created by Suji Jang on 10/1/25.
//

import UIKit
import SnapKit

final class SectionHeaderView: UICollectionReusableView {
    
    // MARK: - UI Components
    private let titleLabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .label
        return label
    }()
    
    private let showAllButton = {
        let button = UIButton(type: .system)
        button.setTitle("전체보기", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        button.semanticContentAttribute = .forceRightToLeft
        button.tintColor = SignatureColor.main
        return button
    }()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupHierarchy()
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupHierarchy() {
        addSubview(titleLabel)
        addSubview(showAllButton)
    }
    
    private func setupLayout() {
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
        
        showAllButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
    }
    
    // MARK: - Configuration
    func configure(title: String) {
        titleLabel.text = title
    }
}

extension SectionHeaderView: ReusableViewProtocol {
    static var identifier: String {
        return String(describing: self)
    }
}
