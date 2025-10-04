//
//  BaseViewController.swift
//  GameFinder
//
//  Created by Suji Jang on 9/27/25.
//

import UIKit

class BaseViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureHierarchy()
        configureLayout()
        configureView()
    }
    
    func configureHierarchy() { }
    func configureLayout() { }
    func configureView() {
        view.backgroundColor = .systemBackground
    }
    
    deinit {
        print("deinit: \(String(describing: type(of: self)))")
    }
}
