//
//  HeaderDetailViewController.swift
//  GameFinder
//
//  Created by Suji Jang on 10/4/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import Kingfisher

enum DetailItem: Hashable {
    case header(title: String, releaseDate: String?)
    case game(Game)
    case skeleton(id: Int)
}

final class HeaderDetailViewController: BaseViewController {

    // MARK: - Properties
    private let viewModel: HeaderDetailViewModel
    private let disposeBag = DisposeBag()
    private let viewWillAppearRelay = PublishRelay<Void>()
    private let loadNextPageRelay = PublishRelay<Void>()
    private var isLoading = true
    private var loadingStartTime: Date?
    private var previousStandardAppearance: UINavigationBarAppearance?
    private var previousScrollEdgeAppearance: UINavigationBarAppearance?
    private var previousCompactAppearance: UINavigationBarAppearance?
    private var previousTintColor: UIColor?

    // MARK: - UI Components
    private let backgroundImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemBackground
        imageView.isHidden = true  // 초기에는 완전히 숨김
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

    private let topGradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [
            UIColor.systemBackground.cgColor,
            UIColor.clear.cgColor
        ]
        layer.locations = [0.0, 0.3]
        return layer
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = createLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.6)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.delegate = self
        collectionView.isHidden = true  // 초기에는 완전히 숨김
        return collectionView
    }()

    private let loadingIndicatorBackground = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.alpha = 0
        return view
    }()

    private let loadingIndicator = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .Signature
        indicator.hidesWhenStopped = true  // 멈추면 자동으로 숨김
        return indicator
    }()

    // MARK: - Initialization
    init(viewModel: HeaderDetailViewModel) {
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
        showLoadingIndicator()  // 로딩 인디케이터 표시
        bind()
    }

    private func showLoadingIndicator() {
        loadingStartTime = Date()  // 로딩 시작 시간 기록
        loadingIndicatorBackground.alpha = 1
        loadingIndicator.startAnimating()
    }

    private func hideLoadingIndicator() {
        guard let startTime = loadingStartTime else {
            // 시작 시간이 없으면 바로 숨김
            loadingIndicator.stopAnimating()
            UIView.animate(withDuration: 0.3) {
                self.loadingIndicatorBackground.alpha = 0
            }
            return
        }

        let elapsedTime = Date().timeIntervalSince(startTime)
        let minimumLoadingTime: TimeInterval = 1.0
        let remainingTime = max(0, minimumLoadingTime - elapsedTime)

        // 최소 1초가 지나지 않았으면 남은 시간만큼 대기 후 숨김
        DispatchQueue.main.asyncAfter(deadline: .now() + remainingTime) { [weak self] in
            guard let self = self else { return }
            self.loadingIndicator.stopAnimating()
            UIView.animate(withDuration: 0.3) {
                self.loadingIndicatorBackground.alpha = 0
            }
            self.loadingStartTime = nil
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
        applyTransparentNavigationBarAppearance()

        // Screen View 로깅
        LogManager.logScreenView("HeaderDetail", screenClass: "HeaderDetailViewController")

        viewWillAppearRelay.accept(())
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        restoreNavigationBarAppearance()
    }

    private func setupNavigationBar() {
        navigationController?.navigationBar.tintColor = .secondaryLabel
        navigationItem.backButtonDisplayMode = .minimal
    }

    private func applyTransparentNavigationBarAppearance() {
        guard let navigationBar = navigationController?.navigationBar else { return }

        previousStandardAppearance = navigationBar.standardAppearance.copy() as? UINavigationBarAppearance
        previousScrollEdgeAppearance = navigationBar.scrollEdgeAppearance?.copy() as? UINavigationBarAppearance
        previousCompactAppearance = navigationBar.compactAppearance?.copy() as? UINavigationBarAppearance
        previousTintColor = navigationBar.tintColor

        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]

        let buttonAppearance = UIBarButtonItemAppearance(style: .plain)
        buttonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.secondaryLabel]
        buttonAppearance.highlighted.titleTextAttributes = [.foregroundColor: UIColor.secondaryLabel]
        appearance.buttonAppearance = buttonAppearance

        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactAppearance = appearance
        navigationBar.tintColor = .secondaryLabel
    }

    private func restoreNavigationBarAppearance() {
        guard let navigationBar = navigationController?.navigationBar else { return }

        if let previousStandardAppearance {
            navigationBar.standardAppearance = previousStandardAppearance
        }

        if let previousScrollEdgeAppearance {
            navigationBar.scrollEdgeAppearance = previousScrollEdgeAppearance
        } else {
            navigationBar.scrollEdgeAppearance = navigationBar.standardAppearance
        }

        navigationBar.compactAppearance = previousCompactAppearance
        navigationBar.tintColor = previousTintColor ?? .secondaryLabel
    }

    // MARK: - Setup
    override func configureHierarchy() {
        view.addSubview(backgroundImageView)
        backgroundImageView.layer.addSublayer(gradientLayer)
        backgroundImageView.layer.addSublayer(topGradientLayer)
        view.addSubview(collectionView)
        view.addSubview(loadingIndicatorBackground)
        view.addSubview(loadingIndicator)
    }

    override func configureLayout() {
        let screenWidth = view.frame.width
        let backgroundHeight = screenWidth * 3 / 4
        let backgroundTopOffset: CGFloat = 40
        let collectionStartPoint = backgroundHeight * 1 / 4  // 배경 이미지 1/4 지점

        backgroundImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(backgroundTopOffset)
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(backgroundHeight)
        }

        collectionView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.bottom.equalToSuperview()
        }

        loadingIndicatorBackground.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        loadingIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        // 컬렉션뷰 contentInset을 배경 이미지 1/4 지점부터 시작하도록 설정
        collectionView.contentInset = UIEdgeInsets(top: collectionStartPoint, left: 0, bottom: 0, right: 0)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradientLayer.frame = backgroundImageView.bounds
        topGradientLayer.frame = backgroundImageView.bounds
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
        let input = HeaderDetailViewModel.Input(
            viewWillAppear: viewWillAppearRelay,
            loadNextPage: loadNextPageRelay
        )

        let output = viewModel.transform(input: input)

        output.games
            .asDriver()
            .drive(with: self) { owner, games in
                owner.isLoading = false
                owner.hideLoadingIndicator()
                owner.updateDataSource(with: games)

                // CollectionView 표시 (페이드 인 효과)
                owner.collectionView.alpha = 0
                owner.collectionView.isHidden = false
                UIView.animate(withDuration: 0.3) {
                    owner.collectionView.alpha = 1
                }

                // 첫 번째 게임의 배경 이미지 설정
                if let firstGame = games.first,
                   let backgroundImageString = firstGame.backgroundImage,
                   !backgroundImageString.isEmpty,
                   let imageURL = URL(string: backgroundImageString) {
                    owner.backgroundImageView.kf.setImage(
                        with: imageURL,
                        placeholder: nil,
                        options: [.transition(.fade(0.3))]
                    ) { result in
                        // 이미지 로드 완료 후 페이드 인
                        owner.backgroundImageView.alpha = 0
                        owner.backgroundImageView.isHidden = false
                        UIView.animate(withDuration: 0.3) {
                            owner.backgroundImageView.alpha = 1
                        }
                    }
                } else {
                    // 이미지가 없어도 배경은 표시
                    owner.backgroundImageView.alpha = 0
                    owner.backgroundImageView.isHidden = false
                    UIView.animate(withDuration: 0.3) {
                        owner.backgroundImageView.alpha = 1
                    }
                }
            }
            .disposed(by: disposeBag)

        output.errorAlertMessage
            .asDriver(onErrorJustReturn: "에러 발생")
            .drive(with: self) { owner, message in
                owner.isLoading = false
                owner.hideLoadingIndicator()

                // 에러 시에도 collectionView 표시 (페이드 인 효과)
                owner.collectionView.alpha = 0
                owner.collectionView.isHidden = false
                UIView.animate(withDuration: 0.3) {
                    owner.collectionView.alpha = 1
                }

                owner.showAlert(title: L10n.error, message: message)
            }
            .disposed(by: disposeBag)
    }

    // MARK: - DataSource
    private func updateDataSource(with games: [Game]) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, DetailItem>()
        snapshot.appendSections([0])

        // 첫 번째 아이템: 헤더
        let releaseDate = (viewModel.sectionType == .upcomingGames) ? games.first?.released : nil
        var items: [DetailItem] = [.header(title: viewModel.sectionTitle, releaseDate: releaseDate)]

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

                let isUpcoming = self.viewModel.sectionType == .upcomingGames

                if isUpcoming {
                    // upcomingGames: 알림 버튼만 오른쪽 y축 center에
                    cell.configure(with: game, isUpcoming: true)
                    cell.onNotificationButtonTapped = { [weak self] gameId in
                        guard let self = self else { return }
                        let snapshot = self.dataSource.snapshot()
                        if let gameItem = snapshot.itemIdentifiers.first(where: {
                            if case .game(let g) = $0, g.id == gameId {
                                return true
                            }
                            return false
                        }),
                        case .game(let game) = gameItem {
                            self.handleNotificationToggle(for: game)
                        }
                    }
                } else {
                    // 나머지 섹션: 좋아요 버튼만 오른쪽 y축 center에
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
                }

                return cell
            }
        }
        return dataSource
    }()
}

// MARK: - UICollectionViewDelegate
extension HeaderDetailViewController: UICollectionViewDelegate {
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
