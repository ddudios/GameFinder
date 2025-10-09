//
//  LibraryViewController.swift
//  GameFinder
//
//  Created by Suji Jang on 9/29/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import Kingfisher

enum LibraryCategory: Int, CaseIterable {
    case diary
    case favorite
    case notification

    var title: String {
        switch self {
        case .diary: return "Diary"
        case .favorite: return "Favorite"
        case .notification: return "Notification"
        }
    }

    var icon: String {
        switch self {
        case .diary: return "bookmark.fill"
        case .favorite: return "heart.fill"
        case .notification: return "bell.fill"
        }
    }
}

final class LibraryViewController: BaseViewController {

    // MARK: - Properties
    private let disposeBag = DisposeBag()
    private let viewWillAppearRelay = PublishRelay<Void>()
    private var currentCategory: LibraryCategory = .diary

    // MARK: - UI Components
    private let categoryButtonsStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 20
        return stackView
    }()

    private lazy var readingButton = createCategoryButton(for: .diary)
    private lazy var favoriteButton = createCategoryButton(for: .favorite)
    private lazy var notificationButton = createCategoryButton(for: .notification)

    private lazy var categoryPageViewController: UIPageViewController = {
        let pageVC = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            options: nil
        )
        pageVC.dataSource = self
        pageVC.delegate = self
        return pageVC
    }()

    private var categoryViewControllers: [UIViewController] = []

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCategoryViewControllers()
        setupPageViewController()
        bind()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
        viewWillAppearRelay.accept(())
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        CATransaction.commit()
    }

    // MARK: - Setup
    private func setNavigationBar() {
        navigationItem.title = L10n.Library.navTitle
    }

    override func configureHierarchy() {
        view.addSubview(categoryButtonsStackView)
        categoryButtonsStackView.addArrangedSubview(readingButton)
        categoryButtonsStackView.addArrangedSubview(favoriteButton)
        categoryButtonsStackView.addArrangedSubview(notificationButton)

        addChild(categoryPageViewController)
        view.addSubview(categoryPageViewController.view)
        categoryPageViewController.didMove(toParent: self)
    }

    override func configureLayout() {
        categoryButtonsStackView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.centerX.equalToSuperview()
            make.height.equalTo(60)
        }

        categoryPageViewController.view.snp.makeConstraints { make in
            make.top.equalTo(categoryButtonsStackView.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
    }

    override func configureView() {
        super.configureView()
        setNavigationBar()
    }

    // MARK: - Category Buttons
    private func createCategoryButton(for category: LibraryCategory) -> UIButton {
        let button = UIButton(type: .system)

        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: category.icon)
        config.imagePlacement = .top

        let imageConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        config.preferredSymbolConfigurationForImage = imageConfig

        button.configuration = config
        button.tag = category.rawValue
        button.addTarget(self, action: #selector(categoryButtonTapped(_:)), for: .touchUpInside)

        return button
    }

    @objc private func categoryButtonTapped(_ sender: UIButton) {
        guard let category = LibraryCategory(rawValue: sender.tag) else { return }
        selectCategory(category)
    }

    private func selectCategory(_ category: LibraryCategory) {
        currentCategory = category
        updateButtonStates()

        let direction: UIPageViewController.NavigationDirection = category.rawValue > currentCategory.rawValue ? .forward : .reverse

        categoryPageViewController.setViewControllers(
            [categoryViewControllers[category.rawValue]],
            direction: direction,
            animated: true
        )
    }

    private func updateButtonStates() {
        [readingButton, favoriteButton, notificationButton].forEach { button in
            guard let category = LibraryCategory(rawValue: button.tag) else { return }

            var config = button.configuration
            if category == currentCategory {
                // 선택된 상태: 각 카테고리별 색상
                switch category {
                case .diary:
                    config?.baseForegroundColor = .Signature
                case .favorite:
                    config?.baseForegroundColor = .systemRed
                case .notification:
                    config?.baseForegroundColor = .systemOrange
                }
            } else {
                // 선택되지 않은 상태: .label
                config?.baseForegroundColor = .label
            }
            button.configuration = config
        }
    }

    // MARK: - Page View Controller Setup
    private func setupCategoryViewControllers() {
        for category in LibraryCategory.allCases {
            let vc = LibraryCategoryViewController(category: category)
            categoryViewControllers.append(vc)
        }
    }

    private func setupPageViewController() {
        if let firstVC = categoryViewControllers.first {
            categoryPageViewController.setViewControllers(
                [firstVC],
                direction: .forward,
                animated: false
            )
        }
        updateButtonStates()
    }

    private func bind() {
        // 필요한 경우 추가 바인딩
    }
}

// MARK: - UIPageViewControllerDataSource
extension LibraryViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = categoryViewControllers.firstIndex(of: viewController) else { return nil }
        let previousIndex = index - 1
        guard previousIndex >= 0 else { return nil }
        return categoryViewControllers[previousIndex]
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = categoryViewControllers.firstIndex(of: viewController) else { return nil }
        let nextIndex = index + 1
        guard nextIndex < categoryViewControllers.count else { return nil }
        return categoryViewControllers[nextIndex]
    }
}

// MARK: - UIPageViewControllerDelegate
extension LibraryViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed,
              let currentVC = pageViewController.viewControllers?.first,
              let index = categoryViewControllers.firstIndex(of: currentVC),
              let category = LibraryCategory(rawValue: index) else { return }

        currentCategory = category
        updateButtonStates()
    }
}

// MARK: - Library Category ViewController
final class LibraryCategoryViewController: UIViewController {

    private let category: LibraryCategory
    private let disposeBag = DisposeBag()
    private var readingGames: [Game] = []
    private var favoriteGames: [Game] = []
    private var notificationGames: [Game] = []

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.dataSource = self
        return collectionView
    }()

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.font = .Body.regular14
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    init(category: LibraryCategory) {
        self.category = category
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCollectionView()

        // 카테고리별 데이터 로드
        if category == .diary {
            loadReadingGames()
        } else if category == .favorite {
            loadFavoriteGames()
        } else if category == .notification {
            loadNotificationGames()
        }
    }

    private func setupUI() {
        view.addSubview(collectionView)
        view.addSubview(emptyLabel)

        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        emptyLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(40)
        }

        emptyLabel.text = "No items in \(category.title)"
        emptyLabel.isHidden = true
    }

    private func setupCollectionView() {
        collectionView.register(
            GameListCollectionViewCell.self,
            forCellWithReuseIdentifier: GameListCollectionViewCell.identifier
        )
        collectionView.register(
            GameDiaryListCollectionViewCell.self,
            forCellWithReuseIdentifier: GameDiaryListCollectionViewCell.identifier
        )
    }

    private func loadReadingGames() {
        // ReadingManager의 observeReadings()로 실시간 구독
        ReadingManager.shared.observeReadings()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] games in
                self?.readingGames = games
                self?.collectionView.reloadData()
                self?.emptyLabel.isHidden = !games.isEmpty
            })
            .disposed(by: disposeBag)
    }

    private func loadFavoriteGames() {
        // FavoriteManager의 observeFavorites()로 실시간 구독
        FavoriteManager.shared.observeFavorites()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] games in
                self?.favoriteGames = games
                self?.collectionView.reloadData()
                self?.emptyLabel.isHidden = !games.isEmpty
            })
            .disposed(by: disposeBag)
    }

    private func loadNotificationGames() {
        // NotificationManager의 observeNotifications()로 실시간 구독
        NotificationManager.shared.observeNotifications()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] games in
                self?.notificationGames = games
                self?.collectionView.reloadData()
                self?.emptyLabel.isHidden = !games.isEmpty
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - UICollectionViewDataSource
extension LibraryCategoryViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch category {
        case .diary:
            return readingGames.count
        case .favorite:
            return favoriteGames.count
        case .notification:
            return notificationGames.count
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch category {
        case .diary:
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: GameDiaryListCollectionViewCell.identifier,
                for: indexPath
            ) as? GameDiaryListCollectionViewCell else {
                return UICollectionViewCell()
            }

            let game = readingGames[indexPath.item]
            cell.configure(with: game, lastUpdatedDate: game.readingUpdatedAt)
            return cell

        case .favorite, .notification:
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: GameListCollectionViewCell.identifier,
                for: indexPath
            ) as? GameListCollectionViewCell else {
                return UICollectionViewCell()
            }

            if category == .favorite {
                let game = favoriteGames[indexPath.item]
                cell.configure(with: game, isFavoriteOnly: true)  // Favorite 형태로 표시 (좋아요 버튼만 오른쪽 중앙)
                cell.onFavoriteButtonTapped = { [weak self] gameId in
                    guard let self = self else { return }
                    if let game = self.favoriteGames.first(where: { $0.id == gameId }) {
                        FavoriteManager.shared.toggleFavorite(game)
                    }
                }
            } else {
                let game = notificationGames[indexPath.item]
                cell.configure(with: game, isUpcoming: true)  // upcomingGames 형태로 표시 (좋아요 버튼 숨김, 알림 버튼만 표시)
                cell.onNotificationButtonTapped = { [weak self] gameId in
                    guard let self = self else { return }
                    if let game = self.notificationGames.first(where: { $0.id == gameId }) {
                        NotificationManager.shared.toggleNotification(game)
                    }
                }
            }

            return cell
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension LibraryCategoryViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width

        switch category {
        case .diary:
            // 한 줄에 2개, 여백 고려
            let spacing: CGFloat = 16
            let itemWidth = (width - spacing * 3) / 2 // 양쪽 16 + 중간 16
            let itemHeight = itemWidth * 1.2 // 비율 조정
            return CGSize(width: itemWidth, height: itemHeight)
        case .favorite, .notification:
            // horizontal padding 16씩 고려
            return CGSize(width: width - 32, height: 100)
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        switch category {
        case .diary:
            return UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        case .favorite, .notification:
            return UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        switch category {
        case .diary:
            return 16
        case .favorite, .notification:
            return 0
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        switch category {
        case .diary:
            return 16
        case .favorite, .notification:
            return 0
        }
    }
}

// MARK: - UICollectionViewDelegate
extension LibraryCategoryViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let game: Game
        switch category {
        case .diary:
            game = readingGames[indexPath.item]
            // Reading 카테고리: DiaryViewController로 이동
            let diaryVC = DiaryViewController(gameId: game.id, gameName: game.name)
            navigationController?.pushViewController(diaryVC, animated: true)
            return

        case .favorite:
            game = favoriteGames[indexPath.item]
        case .notification:
            game = notificationGames[indexPath.item]
        }

        // Favorite, Notification 카테고리: GameDetailViewController로 이동
        let viewModel = GameDetailViewModel(gameId: game.id)
        let detailVC = GameDetailViewController(viewModel: viewModel)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}
