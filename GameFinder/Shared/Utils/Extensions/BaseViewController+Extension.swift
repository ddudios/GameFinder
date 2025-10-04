//
//  BaseViewController+Extension.swift
//  GameFinder
//
//  Created by Suji Jang on 10/1/25.
//

import UIKit

extension BaseViewController {
    func setNavigationLeftTitle(_ title: String) {
        let label = UILabel()
        label.text = title
        label.font = .Title.bold16
        label.textColor = .label
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: label)
    }
    
    func showErrorAlert(message: String) {
        let alert = UIAlertController(
            title: "오류",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}
