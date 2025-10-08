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
        font = .Heading.heavy15
        textColor = .label
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
        font = .Body.semibold14
        textColor = .secondaryLabel
    }
}
