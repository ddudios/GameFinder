//
//  SearchResultViewController.swift
//  GameFinder
//
//  Created by Suji Jang on 10/9/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import Kingfisher

final class SearchResultViewController: BaseViewController {

    // MARK: - Properties
    private let viewModel: SearchResultViewModel
    private let disposeBag = DisposeBag()
    private let viewWillAppearRelay = PublishRelay<Void>()
    private let loadNextPageRelay = PublishRelay<Void>()
    private let filterChangedRelay = PublishRelay<SearchResultViewModel.PlatformFilter>()
    private var isLoading = true
    private var selectedFilter: SearchResultViewModel.PlatformFilter = .all

    // MARK: - UI Components
    private let backgroundImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()

    private let gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [
            UIColor.clear.cgColor,
            UIColor.systemBackground.cgColor
        ]
        layer.locations = [0.3, 1.0]
        return layer
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = createLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.6)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.delegate = self
        return collectionView
    }()

    // MARK: - Initialization
    init(viewModel: SearchResultViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupCollectionView()
        bind()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)

        // Screen View 및 검색 로깅
        LogManager.logScreenView("SearchResult", screenClass: "SearchResultViewController")
        LogManager.logSearch(query: viewModel.query)

        viewWillAppearRelay.accept(())
    }

    private func setupNavigationBar() {
        navigationItem.title = L10n.Search.resultNavTitle
        navigationController?.navigationBar.tintColor = .secondaryLabel
        navigationItem.backButtonDisplayMode = .minimal
        navigationItem.rightBarButtonItem = makeFilterBarButtonItem()
    }

    private func makeFilterBarButtonItem() -> UIBarButtonItem {
        let item = UIBarButtonItem(
            title: selectedFilter.title,
            style: .plain,
            target: nil,
            action: nil
        )
        item.menu = makeFilterMenu()
        return item
    }

    private func makeFilterMenu() -> UIMenu {
        let actions = SearchResultViewModel.PlatformFilter.allCases.map { filter in
            UIAction(
                title: filter.title,
                state: filter == selectedFilter ? .on : .off
            ) { [weak self] _ in
                self?.didSelectFilter(filter)
            }
        }

        return UIMenu(title: "", options: .singleSelection, children: actions)
    }

    private func didSelectFilter(_ filter: SearchResultViewModel.PlatformFilter) {
        guard selectedFilter != filter else { return }
        selectedFilter = filter
        navigationItem.rightBarButtonItem = makeFilterBarButtonItem()
        filterChangedRelay.accept(filter)
    }

    // MARK: - Setup
    override func configureHierarchy() {
        view.addSubview(backgroundImageView)
        backgroundImageView.layer.addSublayer(gradientLayer)
        view.addSubview(collectionView)
    }

    override func configureLayout() {
        let screenWidth = view.frame.width
        let backgroundHeight = screenWidth * 3 / 4  // 4:3 비율
        let collectionStartPoint = backgroundHeight * 1 / 4  // 배경 이미지 1/4 지점

        backgroundImageView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(backgroundHeight)
        }

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.bottom.equalToSuperview()
        }

        // 컬렉션뷰 contentInset을 배경 이미지 1/4 지점부터 시작하도록 설정
        collectionView.contentInset = UIEdgeInsets(top: collectionStartPoint, left: 0, bottom: 0, right: 0)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradientLayer.frame = backgroundImageView.bounds
        CATransaction.commit()
    }

    override func configureView() {
        super.configureView()
    }

    // MARK: - CollectionView Setup
    private func setupCollectionView() {
        collectionView.register(
            HeaderTitleCollectionViewCell.self,
            forCellWithReuseIdentifier: HeaderTitleCollectionViewCell.identifier
        )
        collectionView.register(
            GameListCollectionViewCell.self,
            forCellWithReuseIdentifier: GameListCollectionViewCell.identifier
        )
        collectionView.register(
            ListSkeletonCell.self,
            forCellWithReuseIdentifier: ListSkeletonCell.identifier
        )
    }

    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, layoutEnvironment in
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(100)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(100)
            )
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: groupSize,
                subitems: [item]
            )

            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 0
            section.contentInsets = NSDirectionalEdgeInsets(
                top: 0,
                leading: 16,
                bottom: 20,
                trailing: 16
            )

            return section
        }
        return layout
    }

    // MARK: - Binding
    private func bind() {
        let input = SearchResultViewModel.Input(
            viewWillAppear: viewWillAppearRelay,
            loadNextPage: loadNextPageRelay,
            filterChanged: filterChangedRelay
        )

        let output = viewModel.transform(input: input)

        output.games
            .asDriver()
            .drive(with: self) { owner, games in
                owner.isLoading = false
                owner.updateDataSource(with: games)

                // 첫 번째 게임의 배경 이미지 설정
                if let firstGame = games.first,
                   let backgroundImageString = firstGame.backgroundImage,
                   !backgroundImageString.isEmpty,
                   let imageURL = URL(string: backgroundImageString) {
                    owner.backgroundImageView.kf.setImage(with: imageURL, placeholder: UIImage(named: "noImage"))
                } else {
                    owner.backgroundImageView.image = UIImage(named: "noImage")
                }
            }
            .disposed(by: disposeBag)

        output.errorAlertMessage
            .asDriver(onErrorJustReturn: "에러 발생")
            .drive(with: self) { owner, message in
                owner.showAlert(title: L10n.error, message: message)
            }
            .disposed(by: disposeBag)
    }

    // MARK: - DataSource
    private func updateDataSource(with games: [Game]) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, DetailItem>()
        snapshot.appendSections([0])

        // 첫 번째 아이템: 헤더
        var items: [DetailItem] = [.header(title: "\"\(viewModel.query)\"", releaseDate: nil)]

        // 나머지 아이템: 게임들
        items.append(contentsOf: games.map { .game($0) })

        snapshot.appendItems(items, toSection: 0)
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    private lazy var dataSource: UICollectionViewDiffableDataSource<Int, DetailItem> = {
        let dataSource = UICollectionViewDiffableDataSource<Int, DetailItem>(
            collectionView: collectionView
        ) { collectionView, indexPath, item in
            switch item {
            case .header(let title, let releaseDate):
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: HeaderTitleCollectionViewCell.identifier,
                    for: indexPath
                ) as? HeaderTitleCollectionViewCell else {
                    return UICollectionViewCell()
                }
                cell.configure(with: title, releaseDate: releaseDate)
                return cell

            case .skeleton:
                return collectionView.dequeueReusableCell(
                    withReuseIdentifier: ListSkeletonCell.identifier,
                    for: indexPath
                )

            case .game(let game):
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: GameListCollectionViewCell.identifier,
                    for: indexPath
                ) as? GameListCollectionViewCell else {
                    return UICollectionViewCell()
                }

                // 좋아요 버튼만 오른쪽 y축 center에
                cell.configure(with: game, isFavoriteOnly: true)
                cell.onFavoriteButtonTapped = { [weak self] gameId in
                    guard let self = self else { return }
                    let snapshot = self.dataSource.snapshot()
                    if let gameItem = snapshot.itemIdentifiers.first(where: {
                        if case .game(let g) = $0, g.id == gameId {
                            return true
                        }
                        return false
                    }),
                    case .game(let game) = gameItem {
                        FavoriteManager.shared.toggleFavorite(game)
                    }
                }

                return cell
            }
        }
        return dataSource
    }()
}

// MARK: - UICollectionViewDelegate
extension SearchResultViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let totalItems = dataSource.snapshot().numberOfItems

        // 첫 번째 아이템(헤더)은 제외하고, 마지막에서 3번째 셀에 도달하면 다음 페이지 로드
        if indexPath.item > 0 && indexPath.item >= totalItems - 3 {
            loadNextPageRelay.accept(())
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // 첫 번째 셀(헤더)은 탭 불가
        guard indexPath.item > 0,
              let item = dataSource.itemIdentifier(for: indexPath),
              case .game(let game) = item,
              let cell = collectionView.cellForItem(at: indexPath) else {
            return
        }

        presentGameDetail(gameId: game.id, sourceCell: cell)
    }

    // MARK: - Navigation
    private func presentGameDetail(gameId: Int, sourceCell: UICollectionViewCell? = nil) {
        let viewModel = GameDetailViewModel(gameId: gameId)
        let detailVC = GameDetailViewController(viewModel: viewModel)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}
