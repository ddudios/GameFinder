//
//  LibraryViewController.swift
//  GameFinder
//
//  Created by Suji Jang on 9/29/25.
//

import UIKit

final class LibraryViewController: BaseViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    private func setNavigationBar() {
        navigationItem.title = "Library"
    }
    
    override func configureView() {
        super.configureView()
        setNavigationBar()
    }
}
