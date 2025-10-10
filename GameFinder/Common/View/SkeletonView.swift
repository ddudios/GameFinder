//
//  SkeletonView.swift
//  GameFinder
//
//  Created by Claude on 10/10/25.
//

import UIKit

final class SkeletonView: UIView {

    private let gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.startPoint = CGPoint(x: 0.0, y: 0.5)
        layer.endPoint = CGPoint(x: 1.0, y: 0.5)

        let baseColor = UIColor.systemGray5.cgColor
        let highlightColor = UIColor.systemGray4.cgColor

        layer.colors = [baseColor, highlightColor, baseColor]
        layer.locations = [0.0, 0.5, 1.0]
        return layer
    }()

    private var animation: CABasicAnimation?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayer()
    }

    private func setupLayer() {
        layer.addSublayer(gradientLayer)
        layer.cornerRadius = 8
        clipsToBounds = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }

    func startAnimating() {
        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [-1.0, -0.5, 0.0]
        animation.toValue = [1.0, 1.5, 2.0]
        animation.duration = 1.5
        animation.repeatCount = .infinity
        gradientLayer.add(animation, forKey: "shimmer")
        self.animation = animation
    }

    func stopAnimating() {
        gradientLayer.removeAllAnimations()
        animation = nil
    }
}

// MARK: - UIView Extension for Skeleton
extension UIView {
    private static var skeletonViewKey: UInt8 = 0

    func showSkeletonLoading() {
        guard viewWithTag(999) == nil else { return }

        let skeletonView = SkeletonView()
        skeletonView.tag = 999
        skeletonView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(skeletonView)

        NSLayoutConstraint.activate([
            skeletonView.topAnchor.constraint(equalTo: topAnchor),
            skeletonView.leadingAnchor.constraint(equalTo: leadingAnchor),
            skeletonView.trailingAnchor.constraint(equalTo: trailingAnchor),
            skeletonView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        skeletonView.startAnimating()
    }

    func hideSkeletonLoading() {
        viewWithTag(999)?.removeFromSuperview()
    }
}
