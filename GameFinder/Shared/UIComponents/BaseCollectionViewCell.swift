//
//  BaseCollectionViewCell.swift
//  GameFinder
//
//  Created by Suji Jang on 9/30/25.
//

import UIKit

class BaseCollectionViewCell: UICollectionViewCell {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureHierarchy()
        configureLayout()
        configureView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureHierarchy() { }
    func configureLayout() { }
    func configureView() {
        contentView.backgroundColor = AppColor.selected.palette(for: traitCollection).background
    }
}
