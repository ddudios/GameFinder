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
import RealmSwift
import SafariServices

// DiffableDataSource + CompositionalLayout + UICollectionViewCell/UICollectionReusableView
final class FinderViewController: BaseViewController {

    enum Section: CaseIterable {
        case upcomingGames
        case freeGames
        case discountDeals
        case popularGames

        var headerTitle: String {
            switch self {
            case .upcomingGames:
                return L10n.Finder.upcomingGamesSectionHeader
            case .freeGames:
                return L10n.Finder.freeGamesSectionHeader
            case .discountDeals:
                return L10n.Finder.discountDealsSectionHeader
            case .popularGames:
                return L10n.Finder.popularGamesSectionHeader
            }
        }
    }

    private enum FinderItem: Hashable {
        case game(Game)
        case deal(DiscountDeal)
        case skeleton(id: Int, section: Section)
    }

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewLayout())
        collectionView.delegate = self
        collectionView.backgroundColor = .clear
        collectionView.clipsToBounds = false
        return collectionView
    }()

    private var dataSource: UICollectionViewDiffableDataSource<Section, FinderItem>!

    private var freeRegistration: UICollectionView.CellRegistration<FreeCollectionViewCell, Game>!
    private var popularRegistration: UICollectionView.CellRegistration<CardCollectionViewCell, Game>!
    private var upcomingRegistration: UICollectionView.CellRegistration<CardCollectionViewCell, Game>!
    private var discountRegistration: UICollectionView.CellRegistration<DiscountDealCollectionViewCell, DiscountDeal>!

    private var headerRegistration: UICollectionView.SupplementaryRegistration<SectionHeaderView>!

    private let viewModel = FinderViewModel()
    private let disposeBag = DisposeBag()
    private let viewWillAppear = PublishRelay<Void>()
    private var hasInitializedCenterCell = false

    // Loading states for skeleton view
    private var isLoadingUpcoming = true
    private var isLoadingPopular = true
    private var isLoadingFree = true
    private var isLoadingDiscountDeals = true

    // Auto scroll for upcomingGames
    private var autoScrollTimer: Timer?
    private var currentUpcomingIndex = 0
    private var isAutoScrolling = false
    private var lastUpcomingScrollOffset: CGFloat = 0
    private var upcomingScrollTimer: Timer?

    //MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.collectionViewLayout = createLayout(collectionView: collectionView)
        bind()
        configureCellRegistration()
        updateSnapshot()

//        CustomFont.debugPrintInstalledFonts()
        let realm = try! Realm()
        print(realm.configuration.fileURL?.absoluteString ?? "nil")
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 첫 화면 레이아웃 후 첫 번째 셀의 텍스트와 효과를 즉시 적용
        if !hasInitializedCenterCell && collectionView.visibleCells.count > 0 {
            applyInitialCenterCellEffects()
            hasInitializedCenterCell = true
        }
    }

    private func applyInitialCenterCellEffects() {
        guard let upcomingSectionIndex = sectionIndex(for: .upcomingGames) else { return }

        // 첫 번째 셀에 가운데 셀 효과 즉시 적용
        guard let firstCell = collectionView.cellForItem(at: IndexPath(item: 0, section: upcomingSectionIndex)) as? CardCollectionViewCell else {
            return
        }

        // 확대 효과
        firstCell.contentContainer.transform = CGAffineTransform(scaleX: 1.12, y: 1.12)
        firstCell.layer.zPosition = 1000

        // 텍스트와 배지 표시
        firstCell.floatingTitleLabel.alpha = 1.0
        firstCell.subtitleLabel.alpha = 1.0
        firstCell.badgeView.alpha = 1.0
        firstCell.imageView.alpha = 1.0
    }

    private func updateCenterCellVisibility() {
        let containerWidth = collectionView.bounds.width
        let centerX = collectionView.contentOffset.x + containerWidth / 2

        var closestDistance: CGFloat = .infinity
        var closestCell: CardCollectionViewCell?

        let upcomingSectionIndex = sectionIndex(for: .upcomingGames)

        collectionView.visibleCells.forEach { cell in
            guard let featuredCell = cell as? CardCollectionViewCell,
                  let indexPath = collectionView.indexPath(for: cell),
                  indexPath.section == upcomingSectionIndex else { return }

            let cellCenterX = cell.frame.midX
            let distanceFromCenter = abs(cellCenterX - centerX)

            if distanceFromCenter < closestDistance {
                closestDistance = distanceFromCenter
                closestCell = featuredCell
            }
        }

        // 가운데 셀의 텍스트와 배지만 표시
        collectionView.visibleCells.forEach { cell in
            guard let featuredCell = cell as? CardCollectionViewCell else { return }
            let isCenterCell = (featuredCell === closestCell)
            featuredCell.floatingTitleLabel.alpha = isCenterCell ? 1.0 : 0.0
            featuredCell.subtitleLabel.alpha = isCenterCell ? 1.0 : 0.0
            featuredCell.badgeView.alpha = isCenterCell ? 1.0 : 0.0
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Screen View 로깅
        LogManager.logScreenView("Finder", screenClass: "FinderViewController")

        viewWillAppear.accept(())
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAutoScroll()
        upcomingScrollTimer?.invalidate()
    }

    deinit {
        stopAutoScroll()
        upcomingScrollTimer?.invalidate()
    }

    //MARK: - Bind
    private func bind() {
        let input = FinderViewModel.Input(
            viewWillAppear: viewWillAppear
        )
        let output = viewModel.transform(input: input)

        // 인기 게임 데이터 구독
        output.popularGames
            .observe(on: MainScheduler.instance)
            .subscribe(with: self) { owner, games in
                print("popularGames 받음: \(games.count)개")
                owner.isLoadingPopular = false
                owner.updateSection(.popularGames, with: games)
            }
            .disposed(by: disposeBag)

        // 무료 게임 데이터 구독
        output.freeGames
            .observe(on: MainScheduler.instance)
            .subscribe(with: self) { owner, games in
                print("freeGames 받음: \(games.count)개")
                owner.isLoadingFree = false
                owner.updateSection(.freeGames, with: games)
            }
            .disposed(by: disposeBag)

        // 출시 예정 게임 데이터 구독
        output.upcomingGames
            .observe(on: MainScheduler.instance)
            .subscribe(with: self) { owner, games in
                print("upcomingGames 받음 (내일부터): \(games.count)개")
                owner.isLoadingUpcoming = false
                owner.updateSection(.upcomingGames, with: games)
                // 데이터 로드 후 자동 스크롤 시작
                owner.startAutoScroll()
            }
            .disposed(by: disposeBag)

        // 할인 게임팩 데이터 구독
        output.discountDeals
            .skip(1)
            .observe(on: MainScheduler.instance)
            .subscribe(with: self) { owner, deals in
                print("discountDeals 받음: \(deals.count)개")
                owner.isLoadingDiscountDeals = false
                owner.updateSection(.discountDeals, with: deals)
            }
            .disposed(by: disposeBag)

        // 에러 메시지 구독
        output.errorAlertMessage
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, message in
                owner.showAlert(title: L10n.error, message: message)
            }
            .disposed(by: disposeBag)
    }

    // MARK: - Update Snapshot
    private func updateSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, FinderItem>()

        snapshot.appendSections(Section.allCases)

        let upcomingSkeletons = (1...5).map { FinderItem.skeleton(id: -$0, section: .upcomingGames) }
        let freeSkeletons = (6...8).map { FinderItem.skeleton(id: -$0, section: .freeGames) }
        let discountSkeletons = (9...11).map { FinderItem.skeleton(id: -$0, section: .discountDeals) }
        let popularSkeletons = (12...16).map { FinderItem.skeleton(id: -$0, section: .popularGames) }

        snapshot.appendItems(upcomingSkeletons, toSection: .upcomingGames)
        snapshot.appendItems(freeSkeletons, toSection: .freeGames)
        snapshot.appendItems(discountSkeletons, toSection: .discountDeals)
        snapshot.appendItems(popularSkeletons, toSection: .popularGames)

        dataSource.apply(snapshot, animatingDifferences: false)
    }

    private func updateSection(_ section: Section, with games: [Game]) {
        guard !games.isEmpty else {
            print("\(section) 섹션: 게임 데이터가 비어있음")
            return
        }

        var snapshot = dataSource.snapshot()

        if !snapshot.sectionIdentifiers.contains(section) {
            snapshot.appendSections([section])
        }

        let oldItems = snapshot.itemIdentifiers(inSection: section)
        snapshot.deleteItems(oldItems)

        snapshot.appendItems(games.map { .game($0) }, toSection: section)
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    private func updateSection(_ section: Section, with deals: [DiscountDeal]) {
        var snapshot = dataSource.snapshot()

        if !snapshot.sectionIdentifiers.contains(section) {
            snapshot.appendSections([section])
        }

        let oldItems = snapshot.itemIdentifiers(inSection: section)
        snapshot.deleteItems(oldItems)

        snapshot.appendItems(deals.map { .deal($0) }, toSection: section)
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    //MARK: - Layout
    private func configureNavigationBar() {
        navigationItem.title = L10n.Finder.navTitle
        navigationItem.backButtonTitle = ""

        let searchButton = UIBarButtonItem(
            image: UIImage(systemName: "magnifyingglass"),
            style: .plain,
            target: self,
            action: #selector(searchButtonTapped)
        )
        searchButton.tintColor = .Signature
        navigationItem.rightBarButtonItem = searchButton
    }

    @objc private func searchButtonTapped() {
        let searchVC = SearchViewController()
        navigationController?.pushViewController(searchVC, animated: true)
    }

    // registration 초기화
    private func configureCellRegistration() {
        collectionView.register(CardSkeletonCell.self, forCellWithReuseIdentifier: CardSkeletonCell.identifier)
        collectionView.register(FreeGameSkeletonCell.self, forCellWithReuseIdentifier: FreeGameSkeletonCell.identifier)

        popularRegistration = UICollectionView.CellRegistration<CardCollectionViewCell, Game> { [weak self] cell, _, game in
            // popularGames: 좋아요 버튼만 표시
            cell.configure(with: game, showOnlyFavorite: true)
            cell.onFavoriteButtonTapped = { [weak self] gameId in
                guard let self = self,
                      let targetGame = self.findGame(by: gameId) else { return }
                FavoriteManager.shared.toggleFavorite(targetGame)
            }
        }

        freeRegistration = UICollectionView.CellRegistration<FreeCollectionViewCell, Game> { [weak self] cell, _, game in
            // freeGames: 좋아요 버튼만 표시
            cell.configure(with: game, showOnlyFavorite: true)
            cell.onFavoriteButtonTapped = { [weak self] gameId in
                guard let self = self,
                      let targetGame = self.findGame(by: gameId) else { return }
                FavoriteManager.shared.toggleFavorite(targetGame)
            }
        }

        upcomingRegistration = UICollectionView.CellRegistration<CardCollectionViewCell, Game> { [weak self] cell, _, game in
            // upcomingGames: 알림 버튼만 표시
            cell.configure(with: game, showOnlyNotification: true)
            cell.onNotificationButtonTapped = { [weak self] gameId in
                guard let self = self,
                      let targetGame = self.findGame(by: gameId) else { return }
                self.handleNotificationToggle(for: targetGame)
            }
        }

        discountRegistration = UICollectionView.CellRegistration<DiscountDealCollectionViewCell, DiscountDeal> { cell, _, deal in
            cell.configure(with: deal)
        }

        headerRegistration = UICollectionView.SupplementaryRegistration<SectionHeaderView>(
            elementKind: UICollectionView.elementKindSectionHeader
        ) { supplementaryView, _, indexPath in
            let section = Section.allCases[indexPath.section]
            let alignment: NSTextAlignment = section == .upcomingGames ? .center : .left
            supplementaryView.configure(with: section.headerTitle, alignment: alignment)
        }

        dataSource = UICollectionViewDiffableDataSource<Section, FinderItem>(
            collectionView: collectionView
        ) { [weak self] collectionView, indexPath, itemIdentifier in
            guard let self = self else { return nil }
            let sectionType = Section.allCases[indexPath.section]

            switch itemIdentifier {
            case .skeleton(_, let skeletonSection):
                if skeletonSection == .freeGames || skeletonSection == .discountDeals {
                    return collectionView.dequeueReusableCell(
                        withReuseIdentifier: FreeGameSkeletonCell.identifier,
                        for: indexPath
                    )
                } else {
                    return collectionView.dequeueReusableCell(
                        withReuseIdentifier: CardSkeletonCell.identifier,
                        for: indexPath
                    )
                }

            case .game(let game):
                switch sectionType {
                case .popularGames:
                    return collectionView.dequeueConfiguredReusableCell(
                        using: self.popularRegistration,
                        for: indexPath,
                        item: game
                    )
                case .freeGames:
                    return collectionView.dequeueConfiguredReusableCell(
                        using: self.freeRegistration,
                        for: indexPath,
                        item: game
                    )
                case .upcomingGames:
                    return collectionView.dequeueConfiguredReusableCell(
                        using: self.upcomingRegistration,
                        for: indexPath,
                        item: game
                    )
                case .discountDeals:
                    return collectionView.dequeueReusableCell(
                        withReuseIdentifier: FreeGameSkeletonCell.identifier,
                        for: indexPath
                    )
                }

            case .deal(let deal):
                guard sectionType == .discountDeals else {
                    return collectionView.dequeueReusableCell(
                        withReuseIdentifier: FreeGameSkeletonCell.identifier,
                        for: indexPath
                    )
                }
                return collectionView.dequeueConfiguredReusableCell(
                    using: self.discountRegistration,
                    for: indexPath,
                    item: deal
                )
            }
        }

        dataSource.supplementaryViewProvider = { [weak self] collectionView, _, indexPath in
            guard let self = self else { return nil }

            let header = collectionView.dequeueConfiguredReusableSupplementary(
                using: self.headerRegistration,
                for: indexPath
            )

            let section = Section.allCases[indexPath.section]
            header.onTap = { [weak self] in
                guard let self else { return }
                self.navigateToHeaderDetail(section: section)
            }

            return header
        }
    }

    // MARK: - Navigation
    private func navigateToHeaderDetail(section: Section) {
        switch section {
        case .discountDeals:
            let detailVC = DiscountDealsViewController()
            navigationController?.pushViewController(detailVC, animated: true)
        default:
            let viewModel = HeaderDetailViewModel(sectionType: section)
            let detailVC = HeaderDetailViewController(viewModel: viewModel)
            navigationController?.pushViewController(detailVC, animated: true)
        }
    }

    private func presentGameDetail(gameId: Int, sourceCell: UICollectionViewCell? = nil) {
        let viewModel = GameDetailViewModel(gameId: gameId)
        let detailVC = GameDetailViewController(viewModel: viewModel)
        navigationController?.pushViewController(detailVC, animated: true)
    }

    private func presentDiscountDeal(_ deal: DiscountDeal) {
        guard let url = deal.redirectURL else { return }
        let safariVC = SFSafariViewController(url: url)
        present(safariVC, animated: true)
    }

    override func configureHierarchy() {
        view.addSubview(collectionView)
    }

    override func configureLayout() {
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(4)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
            make.horizontalEdges.equalTo(view.safeAreaLayoutGuide.snp.horizontalEdges).inset(Spacing.xxs)
        }
    }

    override func configureView() {
        super.configureView()
        configureNavigationBar()
    }

    // MARK: - Auto Scroll
    private func startAutoScroll() {
        stopAutoScroll()

        guard dataSource != nil else { return }

        let upcomingItems = upcomingGameItemIndices()
        guard upcomingItems.count > 1 else { return }

        autoScrollTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.scrollToNextUpcomingGame()
        }
    }

    private func stopAutoScroll() {
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
    }

    private func scrollToNextUpcomingGame() {
        let upcomingItemIndices = upcomingGameItemIndices()
        guard !upcomingItemIndices.isEmpty else { return }

        currentUpcomingIndex += 1
        if currentUpcomingIndex >= upcomingItemIndices.count {
            currentUpcomingIndex = 0
        }

        guard let upcomingSectionIndex = sectionIndex(for: .upcomingGames) else { return }

        let targetItemIndex = upcomingItemIndices[currentUpcomingIndex]
        let indexPath = IndexPath(item: targetItemIndex, section: upcomingSectionIndex)

        isAutoScrolling = true
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.isAutoScrolling = false
        }
    }

    private func sectionIndex(for section: Section) -> Int? {
        Section.allCases.firstIndex(of: section)
    }

    private func findGame(by gameId: Int) -> Game? {
        dataSource.snapshot().itemIdentifiers.compactMap { item in
            guard case .game(let game) = item else { return nil }
            return game
        }.first(where: { $0.id == gameId })
    }

    private func upcomingGameItemIndices() -> [Int] {
        let items = dataSource.snapshot().itemIdentifiers(inSection: .upcomingGames)
        return items.enumerated().compactMap { index, item in
            guard case .game = item else { return nil }
            return index
        }
    }
}

//MARK: - UICollectionViewDelegate
extension FinderViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }

        switch item {
        case .game(let game):
            let cell = collectionView.cellForItem(at: indexPath)
            presentGameDetail(gameId: game.id, sourceCell: cell)
        case .deal(let deal):
            presentDiscountDeal(deal)
        case .skeleton:
            break
        }
    }
}

extension FinderViewController {
    private func createLayout(collectionView: UICollectionView) -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { index, layoutEnvironment in
            let sectionType = Section.allCases[index]

            switch sectionType {
            case .upcomingGames:
                let item = NSCollectionLayoutItem(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1),
                        heightDimension: .fractionalHeight(1)
                    )
                )
                item.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 8, bottom: 0, trailing: 8)

                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(0.7),
                    heightDimension: .fractionalWidth(0.7 * 4/3)
                )

                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: groupSize,
                    subitems: [item]
                )

                let section = NSCollectionLayoutSection(group: group)
                section.orthogonalScrollingBehavior = .groupPagingCentered
                section.interGroupSpacing = 20
                section.contentInsets = NSDirectionalEdgeInsets(top: 20,
                                                                leading: 0,
                                                                bottom: 56,
                                                                trailing: 0)

                let headerSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(44)
                )
                let header = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: headerSize,
                    elementKind: UICollectionView.elementKindSectionHeader,
                    alignment: .top
                )
                section.boundarySupplementaryItems = [header]

                section.visibleItemsInvalidationHandler = { [weak self] visibleItems, scrollOffset, layoutEnvironment in
                    guard let self = self else { return }

                    let containerWidth = layoutEnvironment.container.contentSize.width
                    let centerX = scrollOffset.x + containerWidth / 2

                    var closestDistance: CGFloat = .infinity
                    var closestCell: CardCollectionViewCell?
                    var closestIndex = 0

                    visibleItems.forEach { item in
                        guard let cell = collectionView.cellForItem(at: item.indexPath) as? CardCollectionViewCell else { return }

                        let itemCenterX = item.frame.midX
                        let distanceFromCenter = abs(itemCenterX - centerX)

                        if distanceFromCenter < closestDistance {
                            closestDistance = distanceFromCenter
                            closestCell = cell
                            closestIndex = item.indexPath.item
                        }
                    }

                    if scrollOffset.x != self.lastUpcomingScrollOffset {
                        self.lastUpcomingScrollOffset = scrollOffset.x

                        if !self.isAutoScrolling {
                            self.stopAutoScroll()
                        }

                        self.upcomingScrollTimer?.invalidate()

                        self.upcomingScrollTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { [weak self] _ in
                            guard let self = self else { return }

                            self.currentUpcomingIndex = closestIndex

                            if !self.isAutoScrolling {
                                self.startAutoScroll()
                            }
                        }
                    }

                    visibleItems.forEach { item in
                        guard let cell = collectionView.cellForItem(at: item.indexPath) as? CardCollectionViewCell else { return }

                        let itemCenterX = item.frame.midX
                        let distanceFromCenter = abs(itemCenterX - centerX)

                        cell.layer.zPosition = 1000 - distanceFromCenter

                        let normalizedDistance = min(distanceFromCenter / containerWidth, 1.0)
                        let scale = 1.12 - (normalizedDistance * 0.22)

                        let isCenterCell = (cell === closestCell)
                        let dimAlpha: CGFloat = isCenterCell ? 0.0 : 0.4

                        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
                            cell.contentContainer.transform = CGAffineTransform(scaleX: scale, y: scale)
                            cell.imageView.alpha = 1.0 - dimAlpha
                            cell.floatingTitleLabel.alpha = isCenterCell ? 1.0 : 0.0
                            cell.subtitleLabel.alpha = isCenterCell ? 1.0 : 0.0
                            cell.badgeView.alpha = isCenterCell ? 1.0 : 0.0
                        }
                    }
                }
                return section

            case .freeGames, .discountDeals:
                let item = NSCollectionLayoutItem(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1),
                        heightDimension: .absolute(100)
                    )
                )

                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(0.9),
                    heightDimension: .absolute(300)
                )
                let group = NSCollectionLayoutGroup.vertical(
                    layoutSize: groupSize,
                    subitems: [item]
                )

                let section = NSCollectionLayoutSection(group: group)
                section.orthogonalScrollingBehavior = .groupPaging
                section.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                                leading: 0,
                                                                bottom: 16,
                                                                trailing: 0)

                let headerSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(25)
                )
                let header = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: headerSize,
                    elementKind: UICollectionView.elementKindSectionHeader,
                    alignment: .top
                )
                section.boundarySupplementaryItems = [header]

                return section

            case .popularGames:
                let item = NSCollectionLayoutItem(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1),
                        heightDimension: .fractionalHeight(1)
                    )
                )
                item.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 4, bottom: 0, trailing: 4)

                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(0.75),
                    heightDimension: .fractionalWidth(0.75 * 3/4)
                )

                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: groupSize,
                    subitems: [item]
                )

                let section = NSCollectionLayoutSection(group: group)
                section.orthogonalScrollingBehavior = .groupPagingCentered
                section.interGroupSpacing = 20
                section.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                                leading: 0,
                                                                bottom: 50,
                                                                trailing: 0)

                let headerSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(44)
                )
                let header = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: headerSize,
                    elementKind: UICollectionView.elementKindSectionHeader,
                    alignment: .top
                )
                section.boundarySupplementaryItems = [header]

                section.visibleItemsInvalidationHandler = { [weak collectionView] visibleItems, scrollOffset, layoutEnvironment in
                    guard let collectionView = collectionView else { return }

                    let containerWidth = layoutEnvironment.container.contentSize.width
                    let centerX = scrollOffset.x + containerWidth / 2

                    var closestDistance: CGFloat = .infinity
                    var closestCell: CardCollectionViewCell?

                    visibleItems.forEach { item in
                        guard let cell = collectionView.cellForItem(at: item.indexPath) as? CardCollectionViewCell else { return }

                        let itemCenterX = item.frame.midX
                        let distanceFromCenter = abs(itemCenterX - centerX)

                        if distanceFromCenter < closestDistance {
                            closestDistance = distanceFromCenter
                            closestCell = cell
                        }
                    }

                    visibleItems.forEach { item in
                        guard let cell = collectionView.cellForItem(at: item.indexPath) as? CardCollectionViewCell else { return }

                        let itemCenterX = item.frame.midX
                        let distanceFromCenter = abs(itemCenterX - centerX)

                        cell.layer.zPosition = 1000 - distanceFromCenter

                        let normalizedDistance = min(distanceFromCenter / containerWidth, 1.0)
                        let scale = 1.12 - (normalizedDistance * 0.22)

                        let isCenterCell = (cell === closestCell)
                        let dimAlpha: CGFloat = isCenterCell ? 0.0 : 0.4

                        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
                            cell.contentContainer.transform = CGAffineTransform(scaleX: scale, y: scale)
                            cell.imageView.alpha = 1.0 - dimAlpha
                            cell.floatingTitleLabel.alpha = isCenterCell ? 1.0 : 0.0
                            cell.subtitleLabel.alpha = isCenterCell ? 1.0 : 0.0
                            cell.badgeView.alpha = isCenterCell ? 1.0 : 0.0
                        }
                    }
                }
                return section
            }
        }
        return layout
    }
}
