//
//  BlureView.swift
//  GameFinder
//
//  Created by Suji Jang on 9/29/25.
//

import UIKit

final class BlurView: UIVisualEffectView {
    
    // iOS에서 제공하는 얇은 밝은 유리 느낌
    init(style: UIBlurEffect.Style = .systemThinMaterialLight) {
        super.init(effect: UIBlurEffect(style: style))
        
        // 부모 뷰의 크기가 변할 때 이 뷰도 그 크기에 맞추도록 설정 - 변화에 대응
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func attach(to view: UIView) {
        
        // 자신의 크기를 부모 뷰랑 똑같이 맞춤 - 초기 세팅
        frame = view.bounds
        
        // 부모뷰의 맨 뒤쪽(인덱스 0)에 자신을 추가
        view.insertSubview(self, at: 0)
    }
}
