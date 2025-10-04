//
//  HeaderDetailViewController.swift
//  GameFinder
//
//  Created by Claude on 10/4/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import Kingfisher

enum DetailItem: Hashable {
    case header(String)
    case game(Game)
}

final class HeaderDetailViewController: BaseViewController {

    // MARK: - Properties
    private let viewModel: HeaderDetailViewModel
    private let disposeBag = DisposeBag()
    private let viewWillAppearRelay = PublishRelay<Void>()
    private let loadNextPageRelay = PublishRelay<Void>()

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
            UIColor.black.cgColor
        ]
        layer.locations = [0.5, 1.0]
        return layer
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = createLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.delegate = self
        return collectionView
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
        bind()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
        viewWillAppearRelay.accept(())
    }

    private func setupNavigationBar() {
        navigationController?.navigationBar.tintColor = .secondaryLabel
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
        let collectionStartPoint = backgroundHeight * 1 / 2  // 배경 이미지 1/2 지점

        backgroundImageView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(backgroundHeight)
        }

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.bottom.equalToSuperview()
        }

        // 컬렉션뷰 contentInset을 배경 이미지 1/2 지점부터 시작하도록 설정
        collectionView.contentInset = UIEdgeInsets(top: collectionStartPoint, left: 0, bottom: 0, right: 0)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = backgroundImageView.bounds
    }

    override func configureView() {
        super.configureView()
        view.backgroundColor = .black
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
    }

    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { [weak self] sectionIndex, layoutEnvironment in
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
                owner.updateDataSource(with: games)

                // 첫 번째 게임의 배경 이미지 설정 (초기 로드 시에만)
                if owner.backgroundImageView.image == nil,
                   let firstGame = games.first,
                   let backgroundImageString = firstGame.backgroundImage,
                   let imageURL = URL(string: backgroundImageString) {
                    owner.backgroundImageView.kf.setImage(with: imageURL)
                }
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
    private func updateDataSource(with games: [Game]) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, DetailItem>()
        snapshot.appendSections([0])

        // 첫 번째 아이템: 헤더
        var items: [DetailItem] = [.header(viewModel.sectionTitle)]

        // 나머지 아이템: 게임들
        items.append(contentsOf: games.map { .game($0) })

        snapshot.appendItems(items, toSection: 0)
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    private lazy var dataSource: UICollectionViewDiffableDataSource<Int, DetailItem> = {
        let dataSource = UICollectionViewDiffableDataSource<Int, DetailItem>(
            collectionView: collectionView
        ) { collectionView, indexPath, item in
            switch item {
            case .header(let title):
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: HeaderTitleCollectionViewCell.identifier,
                    for: indexPath
                ) as? HeaderTitleCollectionViewCell else {
                    return UICollectionViewCell()
                }
                cell.configure(with: title)
                return cell

            case .game(let game):
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: GameListCollectionViewCell.identifier,
                    for: indexPath
                ) as? GameListCollectionViewCell else {
                    return UICollectionViewCell()
                }
                cell.configure(with: game)
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
              case .game(let game) = item else {
            return
        }

        // 게임 상세 화면으로 이동 (추후 구현)
        print("Selected game: \(game.name)")
    }
}
