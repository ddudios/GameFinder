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

// Identifiable: iOS 5.3+ 아무 기능없는 Protocol, id 프로퍼티를 쓰세요, 고유하게 판별할 수 있는 수단으로 사용하는 코드라는 것이 암묵적인 규약으로 정해짐 (커뮤니케이션 수단)
// - id는 절대 겹치지 않게 값을 세팅해주어야겠다.
// FindViewController.swift 맨 위 Basic 정의 교체
struct Basic: Hashable, Identifiable {
    let id = UUID()
    let name: String
    let rating: Double?
    let imageURL: String?

    init(name: String, rating: Double? = nil, imageURL: String? = nil) {
        self.name = name
        self.rating = rating
        self.imageURL = imageURL
    }
}

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
    private var dataSource: UICollectionViewDiffableDataSource<Section, Basic>!
    // error: Type 'Basic' does not conform to protocol 'Hashable' -> 해결: Basic에 Hashable 프로토콜 채택
    // cell을 꾸미는 로직은 registration프로퍼티로만
    // <어떤 셀 사용, 어떤 데이터 타입 사용>
    private var registration: UICollectionView.CellRegistration<FinderCollectionViewCell, Basic>!
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
    private var featuredRegistration: UICollectionView.CellRegistration<FeaturedGameCell, Basic>!
    
    
    // Hashable한데 데이터가 같으면 어떻게 보일지 테스트하기
    // 더이상 인덱스로 데이터를 판단하지 않고 모델 기반으로 데이터를 판단하기 때문에, 어느 한 부분이라도 데이터가 달라야 한다
    var list = [
        Basic(name: "Jack", rating: 123),/* Basic(name: "Jack", age: 123),*/
        // error: Thread 1: "Fatal: supplied item identifiers are not unique. Duplicate identifiers: {(\n    SeSac7HardwareDatabase.Basic(name: \"Jack\", age: 123)\n)}"
        // 데이터가 완전히 똑같으니까 데이터를 구분할 수 없음, 그래야 데이터를 고유하게 나누어줄 수 있음
        // Hashable한 내용으로 정의되어 있기 때문에 더 이상 indexPath를 통해서 코드를 작성하지 않아도 된다
        // diffable로 사용한다는 것은 인덱스 기준으로 데이터를 조회하지 않는 것을 의미한다
        // 그래서 만약에 diffable로 작성 중에 itemIdentifier 등을 사용하는 위치에서 list[indexPath.row] 등으로 접근한다면 애플이 만들어 놓은 기술의 대전제가 틀리는 것이라서 코드의 의도 여부를 떠나서 잘 모르고 사용하고 있구나
        Basic(name: "Den", rating: 50),
        Basic(name: "Bran", rating: 12),
        Basic(name: "Finn", rating: 23),
        Basic(name: "Hue", rating: 3)
    ]
    
    private let disposeBag = DisposeBag()
    
    //MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
        configureCellRegistration()
        updateSnapshot()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        searchBarContainer.layer.cornerRadius = searchBarContainer.bounds.height / Radius.circle
    }
    
    //MARK: - Helpers
    private func bind() {
        NetworkObservable
            .request(router: RawgRouter.game(id: "326243"), as: GameDetailDTO.self)
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(let dto):
                    let game = dto.toDomain()
                    let item = Basic(
                        name: game.title,
                        rating: game.rating,
                        imageURL: game.backgroundImageURL
                    )

                    var snapshot = self.dataSource.snapshot()

                    if snapshot.sectionIdentifiers.contains(.popularGames) == false {
                        snapshot.appendSections([.popularGames])
                    }
                    
                    let olds = snapshot.itemIdentifiers(inSection: .popularGames)
                    snapshot.deleteItems(olds)
                    snapshot.appendItems([item], toSection: .popularGames)

                    self.dataSource.apply(snapshot, animatingDifferences: true)

                case .failure(let err):
                    print("error:", err)
                }
            })
            .disposed(by: disposeBag)
    }
    
    //MARK: - Layout
    private func configureNavigationBar() {
        navigationItem.title = L10n.Finder.navTitle
    }
    
    // registration 초기화
    private func configureCellRegistration() {
        print(#function)        // Featured 셀 등록
        featuredRegistration = UICollectionView.CellRegistration<FeaturedGameCell, Basic> { cell, _, item in
            cell.setImage(urlString: item.imageURL)
            print(item.imageURL)
            cell.configure(with: item)
        }
        
        // cellForItemAt 셀 디자인 데이터 처리하는 코드
        registration = UICollectionView.CellRegistration<FinderCollectionViewCell, Basic> { cell, indexPath, itemIdentifier in
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
        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, itemIdentifier in
            
            // Section에 따라 다른 셀 반환
            let sectionType = Section.allCases[indexPath.section]
            
            if sectionType == .popularGames {
                return collectionView.dequeueConfiguredReusableCell(
                    using: self.featuredRegistration,
                    for: indexPath,
                    item: itemIdentifier  // itemIdentifier == list[indexPath.row]
                )
            } else {
                return collectionView.dequeueConfiguredReusableCell(
                    using: self.registration,
                    for: indexPath,
                    item: itemIdentifier
                )
            }
        }
    }
    
     // 실질적인 Basic 데이터를 넣어줘야 함
    func updateSnapshot() {
        // 데이터 정의
        var snapshot = NSDiffableDataSourceSnapshot<Section, Basic>()  // 이 스냅샷을 dataSource에 넣어주는 것이기 때문에 같은 타입으로 정의하고 초기화()
        
        // error: Thread 1: "There are currently no sections in the data source. Please add a section first." (섹션이 정의되어 있지 않다. 섹션 먼저 정의해줘야 한다)
        // 인덱스 기준으로 움직이는 것이 아니기 때문에 섹션에 대한 위치만 잘 정해주면 알아서 그 위치에 잘 들어간다
        // 섹션의 수이자 섹션을 구분하기 위한 고유값
        // ([몇 번이라는 네이밍으로 넣어주는 것임]) -> Int일 필요가 없어짐
        //        snapshot.appendSections([10000, 0, 200])  // 섹션이 몇 개가 필요한지 배열로 지정해줌
        //        snapshot.appendSections(["고래밥", "칙촉", "카스타드"])
        //        snapshot.appendSections(["고래밥", "고래밥", "고래밥"])  // error: Thread 1: "Fatal: supplied section identifiers are not unique. Duplicate identifiers: {(\n    \"\\Uace0\\Ub798\\Ubc25\"\n)}" (고유하지 않은 section identifier)
        // 고유하면 되기 때문에 보통 열거형으로 사용 (고유하기만 하면 되어서 꼭 열거형일 필요는 없지만 편리한 도구로 열거형을 사용)
        snapshot.appendSections(Section.allCases)
        
        snapshot.appendItems(list, toSection: .upcomingGames)  // 어떤 섹션에 어떤 데이터를 넣을지
        snapshot.appendItems([Basic(name: "새싹이", rating: 10)], toSection: .freeGames)
        snapshot.appendItems([Basic(name: "sd", rating: 234), Basic(name: "새싹이", rating: 10)], toSection: .popularGames)
        
        // popular 데이터 추가
        snapshot.appendItems([
            Basic(name: "Elden Ring", rating: 95),
            Basic(name: "God of War", rating: 94),
            Basic(name: "Horizon", rating: 88),
            Basic(name: "Ghost of Tsushima", rating: 90),
            Basic(name: "The Last of Us", rating: 93)
        ], toSection: .popularGames)
        
        //        collectionView.reloadData() 대신에
        dataSource.apply(snapshot)  // 이전 이후를 비교해서 달라진 부분만 업데이트
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
// 인덱스를 쓰지 않기 때문에 개발자가 할 수 있는 실수
extension FinderViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print(indexPath)
        
        // 클릭했을 때 데이터를 얻어오고 싶다
        //        print(list[indexPath.item])
        /**
         [2, 1]
         Basic(key: 556661, id: EE5D97FD-D127-475B-81C2-D0B13FF80762, name: "Den", age: 50)
         - 동작은 하지만 Diffable이라면 모델 기반으로 데이터를 다루기 때문에, 이건 index기준으로 데이터를 조회했기 때문에, 만들기 급급했다는 인식을 줄 수 있음
         */
        // Diffable을 사용했다는 것은 index 기반 조회를 더이상 하지 않겠다를 의미한다
        let item = dataSource.itemIdentifier(for: indexPath)
        // dataSource: 모든 섹션과 셀에 대한 정보를 이 프로퍼티가 가지고 있음 (append, apply 모두 dataSource가 알고 있음)
        // 이 메서드를 통해서 선택한 셀에 대한 정보를 꺼내옴 (해당 indexPath를 )
        // index를 관리하지 않고
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
