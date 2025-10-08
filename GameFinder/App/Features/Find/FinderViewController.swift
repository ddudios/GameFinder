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

// DiffableDataSource + CompositionalLayout + UICollectionViewCell/UICollectionReusableView
final class FinderViewController: BaseViewController {
    
    enum Section: CaseIterable {
        case upcomingGames
        case freeGames
        case popularGames

        var headerTitle: String {
            switch self {
            case .upcomingGames:
                return L10n.Finder.upcomingGamesSectionHeader
            case .freeGames:
                return L10n.Finder.freeGamesSectionHeader
            case .popularGames:
                return L10n.Finder.popularGamesSectionHeader
            }
        }
    }
    
    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewLayout())
        collectionView.delegate = self
        collectionView.backgroundColor = .clear
        collectionView.clipsToBounds = false
        return collectionView
    }()
    
    // <섹션을 구분해주는 데이터 타입, 셀의 데이터 타입>
    private var dataSource: UICollectionViewDiffableDataSource<Section, Game>!
    // error: Type 'Basic' does not conform to protocol 'Hashable' -> 해결: Basic에 Hashable 프로토콜 채택
    // cell을 꾸미는 로직은 registration프로퍼티로만
    // <어떤 셀 사용, 어떤 데이터 타입 사용>
    private var freeRegistration: UICollectionView.CellRegistration<FreeCollectionViewCell, Game>!
    // SystemCell이름: UICollectionViewListCell
    // 각 Cell에 들어가는 데이터 타입: String
    // 무조건 들어가는 게 확정 !
    // 선언만
    /**
     configureCellRegistration()
     cellForItemAt [0, 0]
     cell registration [0, 0]
     cellForItemAt [0, 1]
     cell registration [0, 1]
     */// Featured 셀 registration 추가
    private var popularRegistration: UICollectionView.CellRegistration<CardCollectionViewCell, Game>!
    private var upcomingRegistration: UICollectionView.CellRegistration<CardCollectionViewCell, Game>!

    // 헤더 registration
    private var headerRegistration: UICollectionView.SupplementaryRegistration<SectionHeaderView>!
    
    private let viewModel = FinderViewModel()
    private let disposeBag = DisposeBag()
    private let viewWillAppear = PublishRelay<Void>()
    private var hasInitializedCenterCell = false

    // Auto scroll for upcomingGames
    private var autoScrollTimer: Timer?
    private var currentUpcomingIndex = 0
    private var isAutoScrolling = false
    private var lastUpcomingScrollOffset: CGFloat = 0
    
    //MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.collectionViewLayout = createLayout(collectionView: collectionView)
        bind()
        configureCellRegistration()
        updateSnapshot()

//        CustomFont.debugPrintInstalledFonts()
        let realm = try! Realm()
        print(realm.configuration.fileURL)
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
        // 첫 번째 셀에 가운데 셀 효과 즉시 적용
        guard let firstCell = collectionView.cellForItem(at: IndexPath(item: 0, section: 0)) as? CardCollectionViewCell else {
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

        collectionView.visibleCells.forEach { cell in
            guard let featuredCell = cell as? CardCollectionViewCell,
                  let indexPath = collectionView.indexPath(for: cell),
                  indexPath.section == 0 else { return }

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
        viewWillAppear.accept(())
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAutoScroll()
    }

    deinit {
        stopAutoScroll()
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
                owner.updateSection(.popularGames, with: games)
            }
            .disposed(by: disposeBag)

        // 무료 게임 데이터 구독
        output.freeGames
            .observe(on: MainScheduler.instance)
            .subscribe(with: self) { owner, games in
                print("freeGames 받음: \(games.count)개")
                owner.updateSection(.freeGames, with: games)
            }
            .disposed(by: disposeBag)

        // 출시 예정 게임 데이터 구독
        output.upcomingGames
            .observe(on: MainScheduler.instance)
            .subscribe(with: self) { owner, games in
                print("upcomingGames 받음: \(games.count)개")
                owner.updateSection(.upcomingGames, with: games)
                // 데이터 로드 후 자동 스크롤 시작
                owner.startAutoScroll()
            }
            .disposed(by: disposeBag)
        
        // 에러 메시지 구독
        output.errorAlertMessage
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, message in
                owner.showErrorAlert(message: message)
            }
            .disposed(by: disposeBag)
    }
    
    // MARK: - Update Snapshot
    // 실질적인 Basic 데이터를 넣어줘야 함
    private func updateSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Game>()  // 데이터 정의: 이 스냅샷을 dataSource에 넣어주는 것이기 때문에 같은 타입으로 정의하고 초기화()
        
        snapshot.appendSections(Section.allCases)
        // 섹션의 수이자 섹션을 구분하기 위한 고유값
        // 섹션이 몇 개가 필요한지 배열로 지정해줌
        // 고유하면 되기 때문에 보통 열거형으로 사용 (고유하기만 하면 되어서 꼭 열거형일 필요는 없지만 편리한 도구로 열거형을 사용)
        
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    private func updateSection(_ section: Section, with games: [Game]) {

        guard !games.isEmpty else {
            print("\(section) 섹션: 게임 데이터가 비어있음")
            return
        }

        var snapshot = dataSource.snapshot()

        // 섹션이 없으면 추가
        if !snapshot.sectionIdentifiers.contains(section) {
            snapshot.appendSections([section])
        }

        // 기존 아이템 제거
        let oldItems = snapshot.itemIdentifiers(inSection: section)
        snapshot.deleteItems(oldItems)

        // 새 아이템 추가: 어떤 섹션에 어떤 데이터를 넣을지
        snapshot.appendItems(games, toSection: section)

        // collectionView.reloadData() 대신에 이전 이후를 비교해서 달라진 부분만 업데이트
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    //MARK: - Layout
    private func configureNavigationBar() {
        navigationItem.title = L10n.Finder.navTitle
        navigationItem.backButtonTitle = L10n.Finder.navTitle
    }
    
    // registration 초기화
    private func configureCellRegistration() {
        // cellForItemAt 셀 디자인 데이터 처리하는 코드
        popularRegistration = UICollectionView.CellRegistration<CardCollectionViewCell, Game> { [weak self] cell, indexPath, game in
            // popularGames: 좋아요 버튼만 표시
            cell.configure(with: game, showOnlyFavorite: true)
            cell.onFavoriteButtonTapped = { [weak self] gameId in
                guard let self = self else { return }
                let snapshot = self.dataSource.snapshot()
                if let game = snapshot.itemIdentifiers.first(where: { $0.id == gameId }) {
                    FavoriteManager.shared.toggleFavorite(game)
                }
            }
        }

        freeRegistration = UICollectionView.CellRegistration<FreeCollectionViewCell, Game> { [weak self] cell, indexPath, game in
            // freeGames: 좋아요 버튼만 표시
            cell.configure(with: game, showOnlyFavorite: true)
            cell.onFavoriteButtonTapped = { [weak self] gameId in
                guard let self = self else { return }
                let snapshot = self.dataSource.snapshot()
                if let game = snapshot.itemIdentifiers.first(where: { $0.id == gameId }) {
                    FavoriteManager.shared.toggleFavorite(game)
                }
            }
        }

        upcomingRegistration = UICollectionView.CellRegistration<CardCollectionViewCell, Game> { [weak self] cell, indexPath, game in
            // upcomingGames: 알림 버튼만 표시
            cell.configure(with: game, showOnlyNotification: true)
            cell.onNotificationButtonTapped = { [weak self] gameId in
                guard let self = self else { return }
                let snapshot = self.dataSource.snapshot()
                if let game = snapshot.itemIdentifiers.first(where: { $0.id == gameId }) {
                    NotificationManager.shared.toggleNotification(game)
                }
            }
        }

        // 헤더 registration
        headerRegistration = UICollectionView.SupplementaryRegistration<SectionHeaderView>(
            elementKind: UICollectionView.elementKindSectionHeader
        ) { supplementaryView, elementKind, indexPath in
            let section = Section.allCases[indexPath.section]
            let alignment: NSTextAlignment = section == .upcomingGames ? .center : .left
            supplementaryView.configure(with: section.headerTitle, alignment: alignment)
        }
        
        // UICollectionViewDataSource Protocol: 셀 갯수, 셀 재사용 명세
        // -> Class
       // DataSource 수정
        dataSource = UICollectionViewDiffableDataSource<Section, Game>(
            collectionView: collectionView
        ) { collectionView, indexPath, itemIdentifier in
            let sectionType = Section.allCases[indexPath.section]

            if sectionType == .popularGames {
                return collectionView.dequeueConfiguredReusableCell(
                    using: self.popularRegistration,
                    for: indexPath,
                    item: itemIdentifier
                )
            } else if sectionType == .freeGames {
                return collectionView.dequeueConfiguredReusableCell(
                    using: self.freeRegistration,
                    for: indexPath,
                    item: itemIdentifier
                )
            } else {
                // upcomingGames
                return collectionView.dequeueConfiguredReusableCell(
                    using: self.upcomingRegistration,
                    for: indexPath,
                    item: itemIdentifier
                )
            }
        }

        // 헤더 설정
        dataSource.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            guard let self = self else { return nil }

            let header = collectionView.dequeueConfiguredReusableSupplementary(
                using: self.headerRegistration,
                for: indexPath
            )

            if let headerView = header as? SectionHeaderView {
                let section = Section.allCases[indexPath.section]
                headerView.onTap = { [weak self] in
                    guard let self else { return }
                    self.navigateToHeaderDetail(section: section)
                }
            }

            return header
        }
    }

    // MARK: - Navigation
    private func navigateToHeaderDetail(section: Section) {
        let viewModel = HeaderDetailViewModel(sectionType: section)
        let detailVC = HeaderDetailViewController(viewModel: viewModel)
        navigationController?.pushViewController(detailVC, animated: true)
    }

    private func presentGameDetail(gameId: Int, sourceCell: UICollectionViewCell? = nil) {
        let viewModel = GameDetailViewModel(gameId: gameId)
        let detailVC = GameDetailViewController(viewModel: viewModel)
        navigationController?.pushViewController(detailVC, animated: true)
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

        // dataSource가 nil인 경우 early return
        guard dataSource != nil else { return }

        // upcomingGames 섹션의 아이템 수 확인
        let snapshot = dataSource.snapshot()
        let upcomingGamesCount = snapshot.itemIdentifiers(inSection: .upcomingGames).count

        guard upcomingGamesCount > 1 else { return }

        autoScrollTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.scrollToNextUpcomingGame()
        }
    }

    private func stopAutoScroll() {
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
    }

    private func scrollToNextUpcomingGame() {
        let snapshot = dataSource.snapshot()
        let upcomingGamesCount = snapshot.itemIdentifiers(inSection: .upcomingGames).count

        guard upcomingGamesCount > 0 else { return }

        // 다음 인덱스 계산
        currentUpcomingIndex += 1
        if currentUpcomingIndex >= upcomingGamesCount {
            currentUpcomingIndex = 0
        }

        // upcomingGames 섹션은 0번 섹션
        let indexPath = IndexPath(item: currentUpcomingIndex, section: 0)

        isAutoScrolling = true
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)

        // 애니메이션 완료 후 플래그 리셋 (0.5초 후)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.isAutoScrolling = false
        }
    }

}

//MARK: - UICollectionViewDelegate
extension FinderViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let game = dataSource.itemIdentifier(for: indexPath),
              let cell = collectionView.cellForItem(at: indexPath) else { return }
        presentGameDetail(gameId: game.id, sourceCell: cell)
    }
}


extension FinderViewController {
    private func createLayout(collectionView: UICollectionView) -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { index, layoutEnvironment in

            let sectionType = Section.allCases[index]

            if sectionType == .upcomingGames {
                let item = NSCollectionLayoutItem(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1),
                        heightDimension: .fractionalHeight(1)
                    )
                )
                item.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 8, bottom: 0, trailing: 8)  // 셀과 셀 사이 간격

                // 스크린샷과 동일한 비율: 가로 0.85, 세로는 가로의 4/3배
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

                // 섹션 헤더 추가
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

                // 스크롤 시 셀 transform, z-index, 텍스트 가시성 업데이트
                section.visibleItemsInvalidationHandler = { visibleItems, scrollOffset, layoutEnvironment in
                    
                    let containerWidth = layoutEnvironment.container.contentSize.width
                    let centerX = scrollOffset.x + containerWidth / 2

                    var closestDistance: CGFloat = .infinity
                    var closestCell: CardCollectionViewCell?

                    // 먼저 가장 가운데 셀을 찾기
                    visibleItems.forEach { item in
                        guard let cell = collectionView.cellForItem(at: item.indexPath) as? CardCollectionViewCell else { return }

                        let itemCenterX = item.frame.midX
                        let distanceFromCenter = abs(itemCenterX - centerX)

                        if distanceFromCenter < closestDistance {
                            closestDistance = distanceFromCenter
                            closestCell = cell
                        }
                    }

                    // 모든 셀에 transform, z-index, 텍스트 가시성 적용
                    visibleItems.forEach { item in
                        guard let cell = collectionView.cellForItem(at: item.indexPath) as? CardCollectionViewCell else { return }

                        let itemCenterX = item.frame.midX
                        let distanceFromCenter = abs(itemCenterX - centerX)

                        // 중앙에 가까울수록 높은 z-index (왼쪽 셀에 가려지지 않도록)
                        cell.layer.zPosition = 1000 - distanceFromCenter

                        // 가운데 셀일수록 scale이 1.0에 가까움
                        let normalizedDistance = min(distanceFromCenter / containerWidth, 1.0)
                        let scale = 1.12 - (normalizedDistance * 0.22) // 1.12 → 0.9

                        let isCenterCell = (cell === closestCell)

                        // 양 옆 셀은 어둡게 처리
                        let dimAlpha: CGFloat = isCenterCell ? 0.0 : 0.4

                        // contentContainer에만 transform 적용
                        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
                            cell.contentContainer.transform = CGAffineTransform(scaleX: scale, y: scale)
                            cell.imageView.alpha = 1.0 - dimAlpha

                            // 가운데 셀만 텍스트 보이기, 나머지는 완전히 숨김
                            cell.floatingTitleLabel.alpha = isCenterCell ? 1.0 : 0.0
                            cell.subtitleLabel.alpha = isCenterCell ? 1.0 : 0.0
                            cell.badgeView.alpha = isCenterCell ? 1.0 : 0.0
                        }
                    }
                }
                return section

            } else if sectionType == .freeGames {
                // 셀 아이템: 가로 레이아웃 (아이콘 + 텍스트)
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
 
                // 섹션 헤더 추가
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
                
            } else if sectionType == .popularGames {
                // 캐러셀 셀 아이템
                let item = NSCollectionLayoutItem(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1),
                        heightDimension: .fractionalHeight(1)
                    )
                )
                item.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 4, bottom: 0, trailing: 4)  // 셀과 셀 사이 간격

                // 그룹 사이즈 (셀 크기)
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

                // 섹션 헤더 추가
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

                // 스크롤 시 셀 transform, z-index, 텍스트 가시성 업데이트
                section.visibleItemsInvalidationHandler = { [weak collectionView] visibleItems, scrollOffset, layoutEnvironment in
                    guard let collectionView = collectionView else { return }

                    let containerWidth = layoutEnvironment.container.contentSize.width
                    let centerX = scrollOffset.x + containerWidth / 2

                    var closestDistance: CGFloat = .infinity
                    var closestCell: CardCollectionViewCell?

                    // 먼저 가장 가운데 셀을 찾기
                    visibleItems.forEach { item in
                        guard let cell = collectionView.cellForItem(at: item.indexPath) as? CardCollectionViewCell else { return }

                        let itemCenterX = item.frame.midX
                        let distanceFromCenter = abs(itemCenterX - centerX)

                        if distanceFromCenter < closestDistance {
                            closestDistance = distanceFromCenter
                            closestCell = cell
                        }
                    }

                    // 모든 셀에 transform, z-index, 텍스트 가시성 적용
                    visibleItems.forEach { item in
                        guard let cell = collectionView.cellForItem(at: item.indexPath) as? CardCollectionViewCell else { return }

                        let itemCenterX = item.frame.midX
                        let distanceFromCenter = abs(itemCenterX - centerX)

                        // 중앙에 가까울수록 높은 z-index (왼쪽 셀에 가려지지 않도록)
                        cell.layer.zPosition = 1000 - distanceFromCenter

                        // 가운데 셀일수록 scale이 1.0에 가까움
                        let normalizedDistance = min(distanceFromCenter / containerWidth, 1.0)
                        let scale = 1.12 - (normalizedDistance * 0.22) // 1.12 → 0.9

                        let isCenterCell = (cell === closestCell)

                        // 양 옆 셀은 어둡게 처리
                        let dimAlpha: CGFloat = isCenterCell ? 0.0 : 0.4

                        // contentContainer에만 transform 적용
                        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
                            cell.contentContainer.transform = CGAffineTransform(scaleX: scale, y: scale)
                            cell.imageView.alpha = 1.0 - dimAlpha

                            // 가운데 셀만 텍스트 보이기, 나머지는 완전히 숨김
                            cell.floatingTitleLabel.alpha = isCenterCell ? 1.0 : 0.0
                            cell.subtitleLabel.alpha = isCenterCell ? 1.0 : 0.0
                            cell.badgeView.alpha = isCenterCell ? 1.0 : 0.0
                        }
                    }
                }
                return section
                
            } else {
                let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1/3), heightDimension: .fractionalHeight(1.0)))
                item.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4)  // 셀과 셀 사이 간격

                // NSCollectionLayoutSize타입이 필요하다고해서 생성
                // 가상의 사각형 바구니 크기
                //        let groupSize = NSCollectionLayoutSize(widthDimension: .absolute(330), heightDimension: .absolute(80))
                // .fractionalWidth: 비율 기반 사이즈 조절 (디바이스 전체 너비 기준)
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(150))

                // NSCollectionLayoutGroup타입이 필요하다고해서 생성
                // 가상의 사각형 바구니 안에 셀을 그려라
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

                // NSCollectionLayoutSection타입이 필요하다고해서 생성
                let section = NSCollectionLayoutSection(group: group)

                // 섹션 헤더 추가
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

                return section
            }
        }
        return layout
    }
}
