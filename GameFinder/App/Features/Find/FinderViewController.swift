//
//  FindViewController.swift
//  GameFinder
//
//  Created by Suji Jang on 9/29/25.
//

import UIKit

final class FinderViewController: BaseViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    private func setNavigationBar() {
        navigationItem.title = "Game Finder"
    }
    
    override func configureView() {
        super.configureView()
        setNavigationBar()
    }
}
