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

// DiffableDataSource + CompositionalLayout + UICollectionViewCell/UICollectionReusableView
final class FinderViewController: BaseViewController {
    
    enum Section: CaseIterable {
        case popularGames
        case upcomingGames
        case freeGames
    }
    
    private let searchBarContainer = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.borderWidth = Border.thin
        view.clipsToBounds = true
        return view
    }()
    private let searchBarTextField = {
        let textField = UITextField()
        textField.placeholder = L10n.Finder.searchPlaceholder
        return textField
    }()
    private lazy var collectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: FinderViewController.createLayout())
        collectionView.delegate = self
        collectionView.backgroundColor = .clear
        return collectionView
    }()
    
    
    // <섹션을 구분해주는 데이터 타입, 셀의 데이터 타입>
    private var dataSource: UICollectionViewDiffableDataSource<Section, Game>!
    // error: Type 'Basic' does not conform to protocol 'Hashable' -> 해결: Basic에 Hashable 프로토콜 채택
    // cell을 꾸미는 로직은 registration프로퍼티로만
    // <어떤 셀 사용, 어떤 데이터 타입 사용>
    private var registration: UICollectionView.CellRegistration<FinderCollectionViewCell, Game>!
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
    private var featuredRegistration: UICollectionView.CellRegistration<FeaturedGameCell, Game>!
    
    private let viewModel = FinderViewModel()
    private let disposeBag = DisposeBag()
    private let viewWillAppear = PublishRelay<Void>()
    
    //MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
        configureCellRegistration()
        updateSnapshot()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewWillAppear.accept(())
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        searchBarContainer.layer.cornerRadius = searchBarContainer.bounds.height / Radius.circle
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
            } onDisposed: { owner in
                print("popularGames 구독 해제")
            }
            .disposed(by: disposeBag)

        // 무료 게임 데이터 구독
        output.freeGames
            .observe(on: MainScheduler.instance)
            .subscribe(with: self) { owner, games in
                print("freeGames 받음: \(games.count)개")
                owner.updateSection(.freeGames, with: games)
            } onDisposed: { owner in
                print("freeGames 구독 해제")
            }
            .disposed(by: disposeBag)

        // 출시 예정 게임 데이터 구독
        output.upcomingGames
            .observe(on: MainScheduler.instance)
            .subscribe(with: self) { owner, games in
                print("upcomingGames 받음: \(games.count)개")
                owner.updateSection(.upcomingGames, with: games)
            } onDisposed: { owner in
                print("upcomingGames 구독 해제")
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
    }
    
    // registration 초기화
    private func configureCellRegistration() {
        // cellForItemAt 셀 디자인 데이터 처리하는 코드
        featuredRegistration = UICollectionView.CellRegistration<FeaturedGameCell, Game> { cell, indexPath, game in
            cell.configure(with: game)
        }
        
        registration = UICollectionView.CellRegistration<FinderCollectionViewCell, Game> { cell, indexPath, itemIdentifier in
            print("cell registration", indexPath)
            // 위의 registeration을 가져와서 let cell = collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: "고래밥")의 indexPath, item을 매개변수indexPath, itemIdentifier로 전달받아서 실행됨
            
            cell.priceLabel.text = itemIdentifier.name
            
            var content = UIListContentConfiguration.valueCell()//subtitleCell()  // systemCell
            content.text = itemIdentifier.name//self.list[indexPath.item].name  // 작동은 하지만 cellRegistration이 만들어진 애플의 의도를 모르는 것
            content.textProperties.color = .brown
            content.secondaryText = "\(itemIdentifier.id)"
            cell.contentConfiguration = content
            
            var background = UIBackgroundConfiguration.listGroupedCell()
            background.backgroundColor = .lightGray  // 셀의 배경색
            cell.backgroundConfiguration = background
        }
        
        // UICollectionViewDataSource Protocol: 셀 갯수, 셀 재사용 명세
        // -> Class
       // DataSource 수정
        dataSource = UICollectionViewDiffableDataSource<Section, Game>(
            collectionView: collectionView
        ) { collectionView, indexPath, itemIdentifier in
            return collectionView.dequeueConfiguredReusableCell(
                using: self.featuredRegistration,
                for: indexPath,
                item: itemIdentifier
            )
            
            // Section에 따라 다른 셀 반환
//            let sectionType = Section.allCases[indexPath.section]
//            
//            if sectionType == .popularGames {
//                
//                return collectionView.dequeueConfiguredReusableCell(
//                    using: self.featuredRegistration,
//                    for: indexPath,
//                    item: itemIdentifier  // itemIdentifier == list[indexPath.row]
//                )
//            } else {
//                return collectionView.dequeueConfiguredReusableCell(
//                    using: self.registration,
//                    for: indexPath,
//                    item: itemIdentifier
//                )
//            }
        }
    }
    
    
    override func configureHierarchy() {
        view.addSubview(searchBarContainer)
        searchBarContainer.addSubview(searchBarTextField)
        
        view.addSubview(collectionView)
    }
    
    override func configureLayout() {
        searchBarContainer.snp.makeConstraints { make in
            make.horizontalEdges.equalTo(view.safeAreaLayoutGuide.snp.horizontalEdges).inset(Spacing.m)
            make.height.equalTo(ControlHeight.regular)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(Spacing.m)
        }
        
        searchBarTextField.snp.makeConstraints { make in
            make.horizontalEdges.equalTo(searchBarContainer.snp.horizontalEdges).inset(Spacing.m)
            make.centerY.equalToSuperview()
            make.height.equalToSuperview()
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(searchBarContainer.snp.bottom).offset(Spacing.m)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
            make.horizontalEdges.equalTo(view.safeAreaLayoutGuide.snp.horizontalEdges).inset(Spacing.xxs)
        }
    }
    
    override func configureView() {
        super.configureView()
        configureNavigationBar()
        
        let palette = AppColor.selected.palette(for: traitCollection)
        searchBarContainer.layer.borderColor = palette.glassBorder.cgColor
        
        let blur = BlurView(style: .systemThinMaterialLight)
        blur.attach(to: searchBarContainer)
    }
    
}

//MARK: - UICollectionViewDelegate
extension FinderViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        // dataSource: 모든 섹션과 셀에 대한 정보를 이 프로퍼티가 가지고 있음 (append, apply 모두 dataSource가 알고 있음)
        // 이 메서드를 통해서 선택한 셀에 대한 정보를 꺼내옴 (해당 indexPath를 )
        print(item)
        /**
         [1, 0]
         Basic(key: 688503, id: D5FE4DA8-A810-4576-9EAA-4A6779D42A33, name: "Jack", age: 123)
         Optional(SeSac7HardwareDatabase.Basic(key: 386461, id: C9234C87-F44B-46E0-A35B-3FCC129DB2F4, name: "sd", age: 234))
         */
    }
}


extension FinderViewController {
    private static func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { index, _ in
            
            let sectionType = Section.allCases[index]
            
            if sectionType == .popularGames {
                let item = NSCollectionLayoutItem(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1),
                        heightDimension: .fractionalHeight(1)
                    )
                )
                item.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)  // 셀과 셀 사이 간격
                
                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(0.8),
                    heightDimension: .absolute(400)
                )
                
                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: groupSize,
                    subitems: [item]
                )
                
                
                let section = NSCollectionLayoutSection(group: group)
                section.orthogonalScrollingBehavior = .groupPagingCentered  // 수평 스크롤 + 그룹 기준으로 가운데 정렬(항상 중앙에 멈춤) (가운데 확대하면 그럴싸한 UI 가능)
                section.interGroupSpacing = 16
                section.contentInsets = NSDirectionalEdgeInsets(
                    top: 20, leading: 24, bottom: 20, trailing: 24
                )
                
                return section
                
            } else if index == 1 {
                let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1/4)))
                item.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)  // 셀과 셀 사이 간격
                
                // outerGroup 기준 크기
                let innerGroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
                
                let innerGroup = NSCollectionLayoutGroup.vertical(layoutSize: innerGroupSize, subitems: [item])
                
                // NSCollectionLayoutSize타입이 필요하다고해서 생성
                // 가상의 사각형 바구니 크기
                // .fractionalWidth: 비율 기반 사이즈 조절 (디바이스 전체 너비 기준)
                let outerGroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.8), heightDimension: .absolute(400))
                
                // NSCollectionLayoutGroup타입이 필요하다고해서 생성
                // 가상의 사각형 바구니 안에 셀을 그려라
                let outerGroup = NSCollectionLayoutGroup.horizontal(layoutSize: outerGroupSize, subitems: [innerGroup])
                
                // NSCollectionLayoutSection타입이 필요하다고해서 생성
                let section = NSCollectionLayoutSection(group: outerGroup)
                //        section.orthogonalScrollingBehavior = .continuous  // 수평 스크롤: 컬렉션뷰 안에 하나의 섹션이 있고 하나의 섹션 안에서 그룹으로 만들 수 있는데, 그 그룹이 옆으로 붙어있음
                section.orthogonalScrollingBehavior = .groupPaging  // 수평 스크롤 + 가속도 설정(그룹 기준 페이징 왼쪽 정렬)
                
                return section
            } else {
                let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1/3), heightDimension: .fractionalHeight(1.0)))
                item.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5)  // 셀과 셀 사이 간격
                
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
                
                return section
            }
        }
        return layout
    }
}
