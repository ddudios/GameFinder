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
    case reading
    case favorite
    case notification

    var title: String {
        switch self {
        case .reading: return "Reading"
        case .favorite: return "Favorite"
        case .notification: return "Notification"
        }
    }

    var icon: String {
        switch self {
        case .reading: return "book.pages.fill"
        case .favorite: return "heart.fill"
        case .notification: return "bell.fill"
        }
    }
}

final class LibraryViewController: BaseViewController {

    // MARK: - Properties
    private let disposeBag = DisposeBag()
    private let viewWillAppearRelay = PublishRelay<Void>()
    private var currentCategory: LibraryCategory = .reading

    // MARK: - UI Components
    private let scrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()

    private let contentView = UIView()

    private let backgroundImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()

    private let blurEffectView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .regular)
        let effectView = UIVisualEffectView(effect: blurEffect)
        return effectView
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

    private let categoryButtonsStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 20
        return stackView
    }()

    private lazy var readingButton = createCategoryButton(for: .reading)
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
        loadRandomBackgroundImage()
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
        gradientLayer.frame = blurEffectView.bounds
        CATransaction.commit()
    }

    // MARK: - Setup
    private func setNavigationBar() {
        navigationItem.title = "Library"
    }

    override func configureHierarchy() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(backgroundImageView)
        contentView.addSubview(blurEffectView)
        blurEffectView.contentView.layer.addSublayer(gradientLayer)

        contentView.addSubview(categoryButtonsStackView)
        categoryButtonsStackView.addArrangedSubview(readingButton)
        categoryButtonsStackView.addArrangedSubview(favoriteButton)
        categoryButtonsStackView.addArrangedSubview(notificationButton)

        addChild(categoryPageViewController)
        contentView.addSubview(categoryPageViewController.view)
        categoryPageViewController.didMove(toParent: self)
    }

    override func configureLayout() {
        let screenWidth = view.frame.width
        let backgroundHeight = screenWidth * 3 / 4

        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView)
            make.width.equalTo(scrollView)
        }

        backgroundImageView.snp.makeConstraints { make in
            make.top.horizontalEdges.equalToSuperview()
            make.height.equalTo(backgroundHeight)
        }

        blurEffectView.snp.makeConstraints { make in
            make.edges.equalTo(backgroundImageView)
        }

        categoryButtonsStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.centerX.equalToSuperview()
            make.height.equalTo(60)
        }

        categoryPageViewController.view.snp.makeConstraints { make in
            make.top.equalTo(categoryButtonsStackView.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(600)
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
                config?.baseForegroundColor = .label
            } else {
                config?.baseForegroundColor = .systemBackground
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

    // MARK: - Background Image
    private func loadRandomBackgroundImage() {
        // upcomingGames와 동일하게 출시 예정 게임의 첫 번째 이미지 가져오기
        let today = Date()
        let futureDate = Calendar.current.date(byAdding: .month, value: 3, to: today)!
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        NetworkObservable.request(
            router: RawgRouter.upcoming(
                start: dateFormatter.string(from: today),
                end: dateFormatter.string(from: futureDate),
                page: 1,
                pageSize: 1
            ),
            as: GameListDTO.self
        )
        .asObservable()
        .subscribe { [weak self] result in
            switch result {
            case .success(let dto):
                if let firstGame = dto.results.first,
                   let imageUrl = firstGame.backgroundImage,
                   let url = URL(string: imageUrl) {
                    self?.backgroundImageView.kf.setImage(with: url, placeholder: UIImage(named: "noImage"))
                } else {
                    self?.backgroundImageView.image = UIImage(named: "noImage")
                }
            case .failure:
                // 실패 시 인기 게임 이미지로 대체
                self?.loadFallbackImage()
            }
        }
        .disposed(by: disposeBag)
    }

    private func loadFallbackImage() {
        // Popular games에서 첫 번째 게임 이미지 가져오기
        NetworkObservable.request(
            router: RawgRouter.popular(page: 1, pageSize: 1),
            as: GameListDTO.self
        )
        .asObservable()
        .subscribe { [weak self] result in
            switch result {
            case .success(let dto):
                if let firstGame = dto.results.first,
                   let imageUrl = firstGame.backgroundImage,
                   let url = URL(string: imageUrl) {
                    self?.backgroundImageView.kf.setImage(with: url, placeholder: UIImage(named: "noImage"))
                } else {
                    self?.backgroundImageView.image = UIImage(named: "noImage")
                }
            case .failure:
                self?.backgroundImageView.image = UIImage(named: "noImage")
            }
        }
        .disposed(by: disposeBag)
    }

    // MARK: - Binding
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

    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 16
        layout.minimumLineSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
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
        emptyLabel.isHidden = false
    }
}
