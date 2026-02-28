//
//  DiscountDealsViewController.swift
//  GameFinder
//
//  Created by Codex on 2/28/26.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import SafariServices

final class DiscountDealsViewController: BaseViewController {

    private enum Section {
        case main
    }

    private enum Item: Hashable {
        case deal(DiscountDeal)
        case skeleton(Int)
    }

    private let viewModel: DiscountDealsViewModel
    private let disposeBag = DisposeBag()

    private let viewWillAppearRelay = PublishRelay<Void>()
    private let loadNextPageRelay = PublishRelay<Void>()

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.delegate = self
        return collectionView
    }()

    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>!
    private var dealRegistration: UICollectionView.CellRegistration<DiscountDealCollectionViewCell, DiscountDeal>!

    init(viewModel: DiscountDealsViewModel = DiscountDealsViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = L10n.Finder.discountDealsSectionHeader
        configureDataSource()
        applyInitialSnapshot()
        bind()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewWillAppearRelay.accept(())
    }

    override func configureHierarchy() {
        view.addSubview(collectionView)
    }

    override func configureLayout() {
        collectionView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }

    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { _, _ in
            let item = NSCollectionLayoutItem(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(104)
                )
            )

            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(104)
                ),
                subitems: [item]
            )

            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 8
            section.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 0, bottom: 20, trailing: 0)
            return section
        }
        return layout
    }

    private func configureDataSource() {
        collectionView.register(FreeGameSkeletonCell.self, forCellWithReuseIdentifier: FreeGameSkeletonCell.identifier)

        dealRegistration = UICollectionView.CellRegistration<DiscountDealCollectionViewCell, DiscountDeal> { cell, _, deal in
            cell.configure(with: deal)
        }

        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) { [weak self] collectionView, indexPath, item in
            guard let self = self else { return nil }

            switch item {
            case .skeleton:
                return collectionView.dequeueReusableCell(
                    withReuseIdentifier: FreeGameSkeletonCell.identifier,
                    for: indexPath
                )
            case .deal(let deal):
                return collectionView.dequeueConfiguredReusableCell(
                    using: self.dealRegistration,
                    for: indexPath,
                    item: deal
                )
            }
        }
    }

    private func bind() {
        let input = DiscountDealsViewModel.Input(
            viewWillAppear: viewWillAppearRelay,
            loadNextPage: loadNextPageRelay
        )

        let output = viewModel.transform(input: input)

        output.deals
            .skip(1)
            .observe(on: MainScheduler.instance)
            .subscribe(with: self) { owner, deals in
                owner.applyDealsSnapshot(deals)
            }
            .disposed(by: disposeBag)

        output.errorAlertMessage
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, message in
                owner.showAlert(title: L10n.error, message: message)
            }
            .disposed(by: disposeBag)
    }

    private func applyInitialSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])
        snapshot.appendItems((1...8).map { Item.skeleton($0) }, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    private func applyDealsSnapshot(_ deals: [DiscountDeal]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])
        snapshot.appendItems(deals.map { .deal($0) }, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    private func openDeal(_ deal: DiscountDeal) {
        guard let url = deal.redirectURL else { return }
        let safariVC = SFSafariViewController(url: url)
        present(safariVC, animated: true)
    }
}

extension DiscountDealsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }

        switch item {
        case .deal(let deal):
            openDeal(deal)
        case .skeleton:
            break
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let frameHeight = scrollView.frame.size.height

        if offsetY > contentHeight - frameHeight * 1.5 {
            loadNextPageRelay.accept(())
        }
    }
}
