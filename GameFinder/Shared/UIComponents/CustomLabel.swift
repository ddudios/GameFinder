//
//  CustomLabel.swift
//  GameFinder
//
//  Created by Suji Jang on 9/30/25.
//

import UIKit

final class TitleLabel: UILabel {
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(text: String) {
        super.init(frame: .zero)
        self.text = text
        font = .Highlight.heavy15
        textColor = AppColor.selected.palette(for: traitCollection).textPrimary
    }
}

final class SubtitleLabel: UILabel {
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(text: String) {
        super.init(frame: .zero)
        self.text = text
        font = .Prominent.semibold14
        textColor = AppColor.selected.palette(for: traitCollection).textSecondary
    }
}
