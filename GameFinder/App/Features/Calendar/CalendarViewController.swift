//
//  CalendarViewController.swift
//  GameFinder
//
//  Created by Suji Jang on 12/21/25.
//

import UIKit
import SnapKit
import FSCalendar
import RxSwift
import RxCocoa

final class CalendarViewController: BaseViewController {

    enum Section: CaseIterable {
        case games
    }

    // MARK: - UI Components
    private let monthYearLabel: UILabel = {
        let label = UILabel()
        label.font = .Title.bold24
        label.textColor = .label
        label.textAlignment = .left
        return label
    }()

    private let calendarView: FSCalendar = {
        let calendar = FSCalendar()
        calendar.backgroundColor = .systemBackground
        calendar.layer.cornerRadius = 12
        calendar.clipsToBounds = true
        return calendar
    }()

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        return collectionView
    }()

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = L10n.Calendar.emptyMessage
        label.font = .Body.regular16
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    private var dataSource: UICollectionViewDiffableDataSource<Section, Game>!
    private var cellRegistration: UICollectionView.CellRegistration<GameCardCell, Game>!

    private let viewModel = CalendarViewModel()
    private let disposeBag = DisposeBag()
    private let dateSelected = PublishRelay<Date>()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureCalendar()
        configureCellRegistration()
        bind()

        // 오늘 날짜로 초기 로드
        dateSelected.accept(Date())
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)

        // Screen View 로깅
        LogManager.logScreenView("Calendar", screenClass: "CalendarViewController")
    }

    // MARK: - Setup
    private func setNavigationBar() {
        // 네비게이션 바 배경색 설정
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }

    override func configureHierarchy() {
        view.addSubview(monthYearLabel)
        view.addSubview(calendarView)
        view.addSubview(collectionView)
        view.addSubview(emptyLabel)
    }

    override func configureLayout() {
        monthYearLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(64)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }

        calendarView.snp.makeConstraints { make in
            make.top.equalTo(monthYearLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(300)
        }

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(calendarView.snp.bottom).offset(16)
            make.leading.trailing.bottom.equalToSuperview()
        }

        emptyLabel.snp.makeConstraints { make in
            make.top.equalTo(calendarView.snp.bottom).offset(80)
            make.leading.trailing.equalToSuperview().inset(32)
        }
    }

    override func configureView() {
        super.configureView()
        setNavigationBar()
    }

    // MARK: - FSCalendar Configuration
    private func configureCalendar() {
        calendarView.delegate = self
        calendarView.dataSource = self

        // 헤더 숨김 (1월 2026년 부분)
        calendarView.headerHeight = 0

        // 외형 설정
        calendarView.appearance.weekdayTextColor = .secondaryLabel
        calendarView.appearance.titleDefaultColor = .label
        calendarView.appearance.weekdayFont = .Body.regular14
        calendarView.appearance.titleFont = .Body.regular14

        // 오늘 날짜: 테두리만 표시
        calendarView.appearance.todayColor = .clear
        calendarView.appearance.titleTodayColor = .label
        calendarView.appearance.borderDefaultColor = .clear
        calendarView.appearance.borderRadius = 1.0

        // 선택한 날짜: 배경색으로 채우기
        calendarView.appearance.selectionColor = .Signature
        calendarView.appearance.titleSelectionColor = .white
        calendarView.appearance.borderSelectionColor = .Signature

        // 오늘 날짜 선택
        calendarView.select(Date())

        // 초기 년/월 레이블 업데이트
        updateMonthYearLabel(for: Date())
    }

    // MARK: - Update Month/Year Label
    private func updateMonthYearLabel(for date: Date) {
        let formatter = DateFormatter()
        formatter.locale = Locale.current

        // 한국어일 때는 "yyyy M월" 형식, 그 외는 "MMMM yyyy" 형식
        if Locale.current.language.languageCode?.identifier == "ko" {
            formatter.dateFormat = "yyyy M월"
        } else {
            formatter.dateFormat = "MMMM yyyy"
        }

        monthYearLabel.text = formatter.string(from: date)
    }

    // MARK: - CollectionView Layout
    private func createLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(0.5),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(200)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 8, bottom: 16, trailing: 8)

        return UICollectionViewCompositionalLayout(section: section)
    }

    // MARK: - Cell Registration
    private func configureCellRegistration() {
        cellRegistration = UICollectionView.CellRegistration<GameCardCell, Game> { cell, indexPath, game in
            cell.configure(with: game)
        }

        dataSource = UICollectionViewDiffableDataSource<Section, Game>(
            collectionView: collectionView
        ) { [weak self] collectionView, indexPath, game in
            guard let self = self else { return UICollectionViewCell() }
            return collectionView.dequeueConfiguredReusableCell(
                using: self.cellRegistration,
                for: indexPath,
                item: game
            )
        }
    }

    // MARK: - Binding
    private func bind() {
        let input = CalendarViewModel.Input(dateSelected: dateSelected)
        let output = viewModel.transform(input: input)

        // 게임 데이터 업데이트
        output.games
            .subscribe(with: self) { owner, games in
                owner.updateSnapshot(with: games)
            }
            .disposed(by: disposeBag)

        // 에러 처리
        output.errorAlertMessage
            .subscribe(with: self) { owner, message in
                owner.showAlert(title: "오류", message: message)
            }
            .disposed(by: disposeBag)
    }

    // MARK: - Update Snapshot
    private func updateSnapshot(with games: [Game]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Game>()
        snapshot.appendSections([.games])
        snapshot.appendItems(games, toSection: .games)
        dataSource.apply(snapshot, animatingDifferences: true)

        // 빈 상태 처리
        let isEmpty = games.isEmpty
        emptyLabel.isHidden = !isEmpty
        collectionView.isHidden = isEmpty
    }

    // MARK: - Alert
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - FSCalendarDelegate, FSCalendarDataSource
extension CalendarViewController: FSCalendarDelegate, FSCalendarDataSource {
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        dateSelected.accept(date)
    }

    func calendarCurrentPageDidChange(_ calendar: FSCalendar) {
        updateMonthYearLabel(for: calendar.currentPage)
    }

    func calendar(_ calendar: FSCalendar, willDisplay cell: FSCalendarCell, for date: Date, at monthPosition: FSCalendarMonthPosition) {
        let isToday = Calendar.current.isDateInToday(date)

        // 기존 테두리 레이어 제거
        cell.layer.sublayers?.forEach { layer in
            if layer.name == "todayBorder" {
                layer.removeFromSuperlayer()
            }
        }

        // 오늘 날짜에만 정원 형태의 테두리 표시
        if isToday {
            let borderLayer = CAShapeLayer()
            borderLayer.name = "todayBorder"
            borderLayer.strokeColor = UIColor.Signature.cgColor
            borderLayer.fillColor = UIColor.clear.cgColor
            borderLayer.lineWidth = 1

            let side = min(cell.bounds.width, cell.bounds.height) * 0.8
            cell.layoutIfNeeded()
            let center = cell.titleLabel.superview?.convert(cell.titleLabel.center, to: cell) ?? cell.titleLabel.center
            let rect = CGRect(
                x: center.x - side / 2,
                y: center.y - side / 2,
                width: side,
                height: side
            )
            .insetBy(dx: borderLayer.lineWidth / 2, dy: borderLayer.lineWidth / 2)

            borderLayer.path = UIBezierPath(ovalIn: rect).cgPath
            cell.layer.addSublayer(borderLayer)
        }
    }
}

// MARK: - UICollectionViewDelegate
extension CalendarViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let game = dataSource.itemIdentifier(for: indexPath) else { return }

        let viewModel = GameDetailViewModel(gameId: game.id)
        let detailVC = GameDetailViewController(viewModel: viewModel)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}
