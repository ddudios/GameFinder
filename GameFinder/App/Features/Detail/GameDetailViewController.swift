//
//  GameDetailViewController.swift
//  GameFinder
//
//  Created by Suji Jang on 10/5/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import Kingfisher

enum GameDetailSection: Int, CaseIterable {
    case screenshots
    case releaseAndRating
    case genreAndTags
    case ageRating
    case platforms
    case description
    case website
    case systemRequirements
    case developerPublisher
}

enum GameDetailItem: Hashable {
    case screenshot(String)
    case releaseAndRating(String?, Double?, Int?)
    case genreAndTags([GameGenre], [GameTag])
    case ageRating(GameESRBRating?)
    case platforms([GamePlatform])
    case description(String?)
    case website(String?)
    case systemRequirements(String?)
    case developerPublisher([GameDeveloper], [GamePublisher])
}

final class GameDetailViewController: BaseViewController {

    // MARK: - Properties
    private let viewModel: GameDetailViewModel
    private let disposeBag = DisposeBag()
    private let viewWillAppearRelay = PublishRelay<Void>()

    private var currentGameDetail: GameDetail?
    private var favoriteButton: UIButton?

    // MARK: - UI Components
    private lazy var collectionView: UICollectionView = {
        let layout = createLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemBackground
        collectionView.showsVerticalScrollIndicator = false
        collectionView.delegate = self
        return collectionView
    }()

    private let pageControl = {
        let pageControl = UIPageControl()
        pageControl.currentPageIndicatorTintColor = .label
        pageControl.pageIndicatorTintColor = .label.withAlphaComponent(0.4)
        pageControl.hidesForSinglePage = true
        pageControl.isUserInteractionEnabled = false
        if #available(iOS 14.0, *) {
            pageControl.backgroundStyle = .minimal
            pageControl.preferredIndicatorImage = UIImage(systemName: "circle.fill")
        }
        return pageControl
    }()

    private var screenshotCount = 0

    // MARK: - Initialization
    init(viewModel: GameDetailViewModel) {
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
        viewWillAppearRelay.accept(())
    }

    // MARK: - Setup
    private func setupNavigationBar() {
        navigationController?.navigationBar.topItem?.backButtonDisplayMode = .minimal
        navigationController?.navigationBar.tintColor = .secondaryLabel

        // Favorite 버튼
        let button = UIButton(type: .custom)
        button.setImage(UIImage(systemName: "heart"), for: .normal)
        button.setImage(UIImage(systemName: "heart.fill"), for: .selected)
        button.tintColor = .systemRed
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(favoriteButtonTapped), for: .touchUpInside)

        favoriteButton = button
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: button)
    }

    override func configureHierarchy() {
        view.addSubview(collectionView)
        view.addSubview(pageControl)
    }

    override func configureLayout() {
        collectionView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        pageControl.snp.makeConstraints { make in
            let screenshotHeight = UIScreen.main.bounds.width * 9 / 16
            make.top.equalTo(collectionView.snp.top).offset(screenshotHeight - 40)
            make.centerX.equalTo(collectionView)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // pageControl을 최상위로 표시
        view.bringSubviewToFront(pageControl)

        // 스크롤 오프셋에 따라 pageControl 위치 업데이트
        updatePageControlPosition()
    }

    private func updatePageControlPosition() {
        let scrollOffset = collectionView.contentOffset.y

        // 아래로 조금이라도 스크롤하면 pageControl 숨김
        UIView.performWithoutAnimation {
            if scrollOffset > 0 {
                pageControl.isHidden = true
            } else {
                pageControl.isHidden = false
            }
        }
    }

    private func setupCollectionView() {
        collectionView.register(
            ScreenshotCollectionViewCell.self,
            forCellWithReuseIdentifier: ScreenshotCollectionViewCell.identifier
        )
        collectionView.register(
            ReleaseAndRatingCollectionViewCell.self,
            forCellWithReuseIdentifier: ReleaseAndRatingCollectionViewCell.identifier
        )
        collectionView.register(
            GenreAndTagsCollectionViewCell.self,
            forCellWithReuseIdentifier: GenreAndTagsCollectionViewCell.identifier
        )
        collectionView.register(
            AgeRatingCollectionViewCell.self,
            forCellWithReuseIdentifier: AgeRatingCollectionViewCell.identifier
        )
        collectionView.register(
            PlatformsCollectionViewCell.self,
            forCellWithReuseIdentifier: PlatformsCollectionViewCell.identifier
        )
        collectionView.register(
            DescriptionCollectionViewCell.self,
            forCellWithReuseIdentifier: DescriptionCollectionViewCell.identifier
        )
        collectionView.register(
            WebsiteCollectionViewCell.self,
            forCellWithReuseIdentifier: WebsiteCollectionViewCell.identifier
        )
        collectionView.register(
            SystemRequirementsCollectionViewCell.self,
            forCellWithReuseIdentifier: SystemRequirementsCollectionViewCell.identifier
        )
        collectionView.register(
            DeveloperPublisherCollectionViewCell.self,
            forCellWithReuseIdentifier: DeveloperPublisherCollectionViewCell.identifier
        )
    }

    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { [weak self] sectionIndex, layoutEnvironment in
            guard let section = GameDetailSection(rawValue: sectionIndex) else { return nil }

            switch section {
            case .screenshots:
                return self?.createScreenshotsSection()
            case .releaseAndRating:
                return self?.createReleaseAndRatingSection()
            case .genreAndTags:
                return self?.createGenreAndTagsSection()
            case .ageRating:
                return self?.createAgeRatingSection()
            case .platforms:
                return self?.createPlatformsSection()
            case .description:
                return self?.createDescriptionSection()
            case .website:
                return self?.createWebsiteSection()
            case .systemRequirements:
                return self?.createSystemRequirementsSection()
            case .developerPublisher:
                return self?.createDeveloperPublisherSection()
            }
        }
        return layout
    }

    // MARK: - Layout Sections
    private func createScreenshotsSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .absolute(UIScreen.main.bounds.width),
            heightDimension: .absolute(UIScreen.main.bounds.width * 9 / 16)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .paging
        section.interGroupSpacing = 0
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 16, trailing: 0)

        // 스크롤 시 페이지 업데이트
        section.visibleItemsInvalidationHandler = { [weak self] visibleItems, point, environment in
            guard let self = self else { return }
            let page = Int(max(0, round(point.x / environment.container.contentSize.width)))
            if page >= 0 && page < self.screenshotCount {
                self.pageControl.currentPage = page
            }
        }

        return section
    }

    private func createReleaseAndRatingSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(1)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(1)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 12, trailing: 16)

        return section
    }

    private func createGenreAndTagsSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(1)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(1)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 12, trailing: 16)

        return section
    }

    private func createAgeRatingSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(1)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(1)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 12, trailing: 16)

        return section
    }

    private func createPlatformsSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(1)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(1)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 12, trailing: 16)

        return section
    }

    private func createDescriptionSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(1)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(1)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 12, trailing: 16)

        return section
    }

    private func createWebsiteSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(1)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(1)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 12, trailing: 16)

        return section
    }

    private func createSystemRequirementsSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(1)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(1)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 12, trailing: 16)

        return section
    }

    private func createDeveloperPublisherSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(1)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(1)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 32, trailing: 16)

        return section
    }

    // MARK: - Binding
    private func bind() {
        let input = GameDetailViewModel.Input(
            viewWillAppear: viewWillAppearRelay
        )

        let output = viewModel.transform(input: input)

        Observable.combineLatest(
            output.gameDetail.asObservable(),
            output.screenshots.asObservable()
        )
        .compactMap { gameDetail, screenshots -> (GameDetail, [Screenshot])? in
            guard let gameDetail = gameDetail else { return nil }
            return (gameDetail, screenshots)
        }
        .asDriver(onErrorJustReturn: (GameDetail(from: GameDetailDTO(id: 0, name: "", nameOriginal: nil, description: nil, descriptionRaw: nil, released: nil, backgroundImage: nil, backgroundImageAdditional: nil, rating: nil, ratingsCount: nil, metacritic: nil, playtime: nil, platforms: nil, genres: nil, developers: nil, publishers: nil, tags: nil, esrbRating: nil)), []))
        .drive(with: self) { owner, data in
            let (gameDetail, screenshots) = data
            owner.currentGameDetail = gameDetail
            owner.navigationItem.title = gameDetail.name
            owner.updateDataSource(with: gameDetail, screenshots: screenshots)

            // Favorite 버튼 상태 업데이트
            owner.favoriteButton?.isSelected = FavoriteManager.shared.isFavorite(gameId: gameDetail.id)

            // 실시간 동기화: 좋아요 상태 변경 구독
            FavoriteManager.shared.favoriteStatusChanged
                .filter { (gameId, _) in gameId == gameDetail.id }
                .observe(on: MainScheduler.instance)
                .subscribe(onNext: { [weak owner] (_, isFavorite) in
                    owner?.favoriteButton?.isSelected = isFavorite
                })
                .disposed(by: owner.disposeBag)
        }
        .disposed(by: disposeBag)

        output.errorAlertMessage
            .asDriver(onErrorJustReturn: "에러 발생")
            .drive(with: self) { owner, message in
                owner.showAlert(message: message)
            }
            .disposed(by: disposeBag)
    }

    // MARK: - DataSource
    private func updateDataSource(with gameDetail: GameDetail, screenshots: [Screenshot]) {
        var snapshot = NSDiffableDataSourceSnapshot<GameDetailSection, GameDetailItem>()

        // Screenshots section - 스크린샷이 있을 때는 그대로, 없을 때는 빈 이미지 표시
        snapshot.appendSections([.screenshots])
        if !screenshots.isEmpty {
            let screenshotItems = screenshots.map { GameDetailItem.screenshot($0.image) }
            snapshot.appendItems(screenshotItems, toSection: .screenshots)

            // PageControl 설정
            screenshotCount = screenshots.count
            pageControl.numberOfPages = screenshots.count
            pageControl.currentPage = 0
            pageControl.isHidden = false
        } else {
            // 스크린샷이 없을 때 빈 이미지 표시
            snapshot.appendItems([.screenshot("")], toSection: .screenshots)
            pageControl.isHidden = true
        }

        // Release and Rating section - 정보가 하나라도 있을 때만 추가
        let hasReleaseInfo = gameDetail.released != nil
        let hasRatingInfo = gameDetail.rating != nil || gameDetail.ratingsCount != nil
        if hasReleaseInfo || hasRatingInfo {
            snapshot.appendSections([.releaseAndRating])
            snapshot.appendItems([.releaseAndRating(gameDetail.released, gameDetail.rating, gameDetail.ratingsCount)], toSection: .releaseAndRating)
        }

        // Genre and Tags section - 장르나 태그가 하나라도 있을 때만 추가
        if !gameDetail.genres.isEmpty || !gameDetail.tags.isEmpty {
            snapshot.appendSections([.genreAndTags])
            snapshot.appendItems([.genreAndTags(gameDetail.genres, gameDetail.tags)], toSection: .genreAndTags)
        }

        // Age Rating section - 연령 등급이 있을 때만 추가
        if let esrbRating = gameDetail.esrbRating {
            snapshot.appendSections([.ageRating])
            snapshot.appendItems([.ageRating(esrbRating)], toSection: .ageRating)
        }

        // Platforms section - 플랫폼이 있을 때만 추가
        if !gameDetail.platforms.isEmpty {
            snapshot.appendSections([.platforms])
            snapshot.appendItems([.platforms(gameDetail.platforms)], toSection: .platforms)
        }

        // Description section - 설명이 있을 때만 추가
        if let description = gameDetail.descriptionRaw, !description.isEmpty {
            snapshot.appendSections([.description])
            snapshot.appendItems([.description(description)], toSection: .description)
        }

        // Developer/Publisher section - 개발사나 퍼블리셔가 하나라도 있을 때만 추가
        if !gameDetail.developers.isEmpty || !gameDetail.publishers.isEmpty {
            snapshot.appendSections([.developerPublisher])
            snapshot.appendItems([.developerPublisher(gameDetail.developers, gameDetail.publishers)], toSection: .developerPublisher)
        }

        dataSource.apply(snapshot, animatingDifferences: false)
    }

    private lazy var dataSource: UICollectionViewDiffableDataSource<GameDetailSection, GameDetailItem> = {
        let dataSource = UICollectionViewDiffableDataSource<GameDetailSection, GameDetailItem>(
            collectionView: collectionView
        ) { collectionView, indexPath, item in
            switch item {
            case .screenshot(let imageUrl):
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: ScreenshotCollectionViewCell.identifier,
                    for: indexPath
                ) as? ScreenshotCollectionViewCell else {
                    return UICollectionViewCell()
                }
                cell.configure(with: imageUrl)
                return cell

            case .releaseAndRating(let releaseDate, let rating, let ratingsCount):
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: ReleaseAndRatingCollectionViewCell.identifier,
                    for: indexPath
                ) as? ReleaseAndRatingCollectionViewCell else {
                    return UICollectionViewCell()
                }
                cell.configure(releaseDate: releaseDate, rating: rating, ratingsCount: ratingsCount)
                return cell

            case .genreAndTags(let genres, let tags):
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: GenreAndTagsCollectionViewCell.identifier,
                    for: indexPath
                ) as? GenreAndTagsCollectionViewCell else {
                    return UICollectionViewCell()
                }
                cell.configure(genres: genres, tags: tags)
                return cell

            case .ageRating(let ageRating):
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: AgeRatingCollectionViewCell.identifier,
                    for: indexPath
                ) as? AgeRatingCollectionViewCell else {
                    return UICollectionViewCell()
                }
                cell.configure(with: ageRating)
                return cell

            case .platforms(let platforms):
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: PlatformsCollectionViewCell.identifier,
                    for: indexPath
                ) as? PlatformsCollectionViewCell else {
                    return UICollectionViewCell()
                }
                cell.configure(with: platforms)
                return cell

            case .description(let description):
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: DescriptionCollectionViewCell.identifier,
                    for: indexPath
                ) as? DescriptionCollectionViewCell else {
                    return UICollectionViewCell()
                }
                cell.configure(with: description)
                return cell

            case .website(let website):
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: WebsiteCollectionViewCell.identifier,
                    for: indexPath
                ) as? WebsiteCollectionViewCell else {
                    return UICollectionViewCell()
                }
                cell.configure(with: website)
                return cell

            case .systemRequirements(let requirements):
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: SystemRequirementsCollectionViewCell.identifier,
                    for: indexPath
                ) as? SystemRequirementsCollectionViewCell else {
                    return UICollectionViewCell()
                }
                cell.configure(with: requirements)
                return cell

            case .developerPublisher(let developers, let publishers):
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: DeveloperPublisherCollectionViewCell.identifier,
                    for: indexPath
                ) as? DeveloperPublisherCollectionViewCell else {
                    return UICollectionViewCell()
                }
                cell.configure(developers: developers, publishers: publishers)
                return cell
            }
        }
        return dataSource
    }()

    // MARK: - Helper
    private func showAlert(message: String) {
        let alert = UIAlertController(
            title: "알림",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Actions
    @objc private func favoriteButtonTapped() {
        guard let gameDetail = currentGameDetail else { return }
        let game = gameDetail.toGame()
        FavoriteManager.shared.toggleFavorite(game)
    }
}

// MARK: - UICollectionViewDelegate
extension GameDetailViewController: UICollectionViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updatePageControlPosition()
    }
}
