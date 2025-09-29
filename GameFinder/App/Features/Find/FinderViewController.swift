//
//  FindViewController.swift
//  GameFinder
//
//  Created by Suji Jang on 9/29/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

// DiffableDataSource + CompositionalLayout + UICollectionViewCell/UICollectionReusableView
final class FinderViewController: BaseViewController {
    //MARK: - Properties
    private let searchBarContainer = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.borderWidth = Border.thin
        view.clipsToBounds = true
        return view
    }()
    private let searchBarTextField = {
        let textField = UITextField()
        textField.placeholder = L10n.Finder.searchPlaceholder
        return textField
    }()
    
    //MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        searchBarContainer.layer.cornerRadius = searchBarContainer.bounds.height / Radius.circle
    }
    
    //MARK: - Helpers
    private func bind() {
        
    }
    
    //MARK: - Layout
    private func setNavigationBar() {
        navigationItem.title = L10n.Finder.navTitle
    }
    
    override func configureHierarchy() {
        view.addSubview(searchBarContainer)
        searchBarContainer.addSubview(searchBarTextField)
    }
    
    override func configureLayout() {
        searchBarContainer.snp.makeConstraints { make in
            make.horizontalEdges.equalTo(view.safeAreaLayoutGuide.snp.horizontalEdges).inset(Spacing.xs)
            make.height.equalTo(ControlHeight.regular)
            make.center.equalToSuperview()
        }
        
        searchBarTextField.snp.makeConstraints { make in
            make.horizontalEdges.equalTo(searchBarContainer.snp.horizontalEdges).inset(Spacing.m)
            make.centerY.equalToSuperview()
            make.height.equalToSuperview()
        }
    }
    
    override func configureView() {
        super.configureView()
        setNavigationBar()
        
        let palette = AppColor.selected.palette(for: traitCollection)
        searchBarContainer.layer.borderColor = palette.glassBorder.cgColor
        
        let blur = BlurView(style: .systemThinMaterialLight)
        blur.attach(to: searchBarContainer)
    }
    
}
