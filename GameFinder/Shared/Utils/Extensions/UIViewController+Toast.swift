//
//  UIViewController+Toast.swift
//  GameFinder
//
//  Created by Suji Jang on 10/11/25.
//

import UIKit

//MARK: - Toast
extension UIViewController {
    func showToast(message: String, duration: TimeInterval = 2.0) {
        let toastContainer = UIView()
        toastContainer.backgroundColor = UIColor.label.withAlphaComponent(0.9)
        toastContainer.alpha = 0.0
        toastContainer.layer.cornerRadius = 10
        toastContainer.clipsToBounds = true

        let toastLabel = UILabel()
        toastLabel.textColor = UIColor.systemBackground
        toastLabel.textAlignment = .center
        toastLabel.font = .Body.regular14
        toastLabel.text = message
        toastLabel.numberOfLines = 0
        toastLabel.lineBreakMode = .byWordWrapping

        toastContainer.addSubview(toastLabel)
        view.addSubview(toastContainer)

        toastLabel.translatesAutoresizingMaskIntoConstraints = false
        toastContainer.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            toastLabel.leadingAnchor.constraint(equalTo: toastContainer.leadingAnchor, constant: 16),
            toastLabel.trailingAnchor.constraint(equalTo: toastContainer.trailingAnchor, constant: -16),
            toastLabel.topAnchor.constraint(equalTo: toastContainer.topAnchor, constant: 12),
            toastLabel.bottomAnchor.constraint(equalTo: toastContainer.bottomAnchor, constant: -12),

            toastContainer.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 40),
            toastContainer.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -40),
            toastContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toastContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])

        UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseIn, animations: {
            toastContainer.alpha = 1.0
        }, completion: { _ in
            UIView.animate(withDuration: 0.3, delay: duration, options: .curveEaseOut, animations: {
                toastContainer.alpha = 0.0
            }, completion: { _ in
                toastContainer.removeFromSuperview()
            })
        })
    }
}

//MARK: - Noti Swizzle
extension UIViewController {
    
    class func swizzleMethod() {
        
        let origin = #selector(viewWillAppear)
        let change = #selector(changeViewWillAppear)
        
        guard let originMethod =
                class_getInstanceMethod (UIViewController.self, origin), let
                changeMethod = class_getInstanceMethod(UIViewController.self,
                                                       change) else {
            print ("함수를 찾을 수 없거나 오류")
            return
        }
        
        method_exchangeImplementations(originMethod, changeMethod)
    }
    
    @objc func changeViewWillAppear() {
        print ("changeViewWillAppear")
    }
}
