//
//  UIView+Skeleton.swift
//  GameFinder
//
//  Created by Suji Jang on 10/5/25.
//

import UIKit

extension UIView {
    private static let skeletonLayerName = "skeletonLayer"
    private static let skeletonAnimationKey = "skeletonAnimation"

    func showSkeleton() {
        // 이미 스켈레톤이 있으면 제거
        hideSkeleton()

        let skeletonLayer = CAGradientLayer()
        skeletonLayer.name = UIView.skeletonLayerName
        skeletonLayer.colors = [
            UIColor.systemGray5.cgColor,
            UIColor.systemGray4.cgColor,
            UIColor.systemGray5.cgColor
        ]
        skeletonLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        skeletonLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        skeletonLayer.locations = [0.0, 0.5, 1.0]
        skeletonLayer.frame = bounds
        skeletonLayer.cornerRadius = layer.cornerRadius

        layer.addSublayer(skeletonLayer)

        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [-1.0, -0.5, 0.0]
        animation.toValue = [1.0, 1.5, 2.0]
        animation.duration = 1.5
        animation.repeatCount = .infinity

        skeletonLayer.add(animation, forKey: UIView.skeletonAnimationKey)
    }

    func hideSkeleton() {
        layer.sublayers?.forEach { sublayer in
            if sublayer.name == UIView.skeletonLayerName {
                sublayer.removeFromSuperlayer()
            }
        }
    }

    func updateSkeletonFrame() {
        layer.sublayers?.forEach { sublayer in
            if sublayer.name == UIView.skeletonLayerName {
                sublayer.frame = bounds
            }
        }
    }
}
