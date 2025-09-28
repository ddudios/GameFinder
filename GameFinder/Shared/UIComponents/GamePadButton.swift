//
//  GamePadButton.swift
//  GameFinder
//
//  Created by Suji Jang on 9/29/25.
//

import UIKit

final class GamePadButton: UIButton {
    enum Kind { case a, b, x, y }

    private let blur = UIVisualEffectView(effect: nil)
    private let ring = CALayer()

    init(kind: Kind) {
        super.init(frame: .zero)
        layer.cornerRadius = 16
        layer.masksToBounds = false

        insertSubview(blur, at: 0)
        blur.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        // 본색 선택
        let base: UIColor = {
            switch kind {
            case .a: return PointColor.a
            case .b: return PointColor.b
            case .x: return PointColor.x
            case .y: return PointColor.y
            }
        }()

        // 상태별 필
        let fills = PointColor.fill(base)
        backgroundColor = fills.normal

        // 유리 블러 + 오버레이
        blur.effect = UIBlurEffect(style: traitCollection.userInterfaceStyle == .dark ? .systemThinMaterialDark : .systemThinMaterialLight)
        blur.frame = bounds

        let overlay = UIView(frame: bounds)
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlay.isUserInteractionEnabled = false
        overlay.backgroundColor = (traitCollection.userInterfaceStyle == .dark) ? PointColor.glassOverlayDark : PointColor.glassOverlayLight
        insertSubview(overlay, aboveSubview: blur)

        // 테두리(유리 스트로크)
        ring.frame = bounds
        ring.cornerRadius = 16
        ring.borderWidth = 1
        ring.borderColor = (traitCollection.userInterfaceStyle == .dark ? PointColor.strokeDark : PointColor.strokeLight).cgColor
        layer.addSublayer(ring)

        // 눌림/해제 상태
        addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.backgroundColor = self.isHighlighted ? fills.pressed : fills.normal
        }, for: .touchDown)
        addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.backgroundColor = fills.normal
        }, for: [.touchUpInside, .touchUpOutside, .touchCancel])
        addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.alpha = self.isEnabled ? 1.0 : 0.6
            self.backgroundColor = self.isEnabled ? fills.normal : fills.disabled
        }, for: .primaryActionTriggered)
    }

    required init?(coder: NSCoder) { nil }
}
