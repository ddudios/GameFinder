//
//  SettingViewController.swift
//  GameFinder
//
//  Created by Suji Jang on 9/29/25.
//

import UIKit

final class SettingViewController: BaseViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    private func setNavigationBar() {
        navigationItem.title = L10n.Settings.navTitle
    }
    
    override func configureView() {
        super.configureView()
        setNavigationBar()
    }
}
