//
//  SearchViewController.swift
//  GameFinder
//
//  Created by Claude on 10/9/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class SearchViewController: BaseViewController {

    // MARK: - Properties
    private let disposeBag = DisposeBag()
    private let platforms = ["Steam", "Mobile", "Nintendo", "PlayStation", "PC"]

    // MARK: - UI Components
    private lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search games..."
        searchBar.searchBarStyle = .minimal
        searchBar.delegate = self
        return searchBar
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = createLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.dataSource = self
        return collectionView
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupCollectionView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    // MARK: - Setup
    private func setupNavigationBar() {
        navigationItem.title = "Search"
        navigationController?.navigationBar.tintColor = .secondaryLabel
        navigationItem.backButtonDisplayMode = .minimal
    }

    private func setupCollectionView() {
        collectionView.register(
            PlatformCardCell.self,
            forCellWithReuseIdentifier: PlatformCardCell.identifier
        )
    }

    override func configureHierarchy() {
        view.addSubview(searchBar)
        view.addSubview(collectionView)
    }

    override func configureLayout() {
        searchBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.horizontalEdges.equalToSuperview().inset(16)
        }

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom).offset(16)
            make.horizontalEdges.equalToSuperview().inset(16)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
    }

    // MARK: - Layout
    private func createLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(120)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(120)
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitems: [item]
        )

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 16
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 0,
            leading: 0,
            bottom: 20,
            trailing: 0
        )

        return UICollectionViewCompositionalLayout(section: section)
    }
}

// MARK: - UICollectionViewDataSource
extension SearchViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return platforms.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: PlatformCardCell.identifier,
            for: indexPath
        ) as? PlatformCardCell else {
            return UICollectionViewCell()
        }

        let platform = platforms[indexPath.item]
        cell.configure(with: platform)
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension SearchViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let platform = platforms[indexPath.item]
        let viewModel = PlatformDetailViewModel(platformName: platform)
        let detailVC = PlatformDetailViewController(viewModel: viewModel)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

// MARK: - UISearchBarDelegate
extension SearchViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let query = searchBar.text, !query.isEmpty else { return }
        searchBar.resignFirstResponder()

        let viewModel = SearchResultViewModel(query: query)
        let resultVC = SearchResultViewController(viewModel: viewModel)
        navigationController?.pushViewController(resultVC, animated: true)
    }
}
