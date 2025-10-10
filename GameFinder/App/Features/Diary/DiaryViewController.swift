//
//  DiaryViewController.swift
//  GameFinder
//
//  Created by Claude on 10/6/25.
//

import UIKit
import SnapKit
import RxSwift
import AVFoundation

final class DiaryViewController: BaseViewController {

    // MARK: - Properties
    private let gameId: Int
    private let gameName: String
    private let disposeBag = DisposeBag()
    private var diaries: [RealmDiary] = []

    // MARK: - UI Components
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .systemBackground
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        return tableView
    }()

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.font = .Body.regular14
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.text = "No diary entries yet.\nTap + to create your first entry."
        label.numberOfLines = 0
        return label
    }()

    // MARK: - Initialization
    init(gameId: Int, gameName: String) {
        self.gameId = gameId
        self.gameName = gameName
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupTableView()
        bind()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    // MARK: - Setup
    private func setupNavigationBar() {
        navigationItem.title = gameName
        navigationController?.navigationBar.topItem?.backButtonDisplayMode = .minimal
        navigationController?.navigationBar.tintColor = .secondaryLabel

        let addButton = UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            style: .plain,
            target: self,
            action: #selector(addButtonTapped)
        )
        navigationItem.rightBarButtonItem = addButton
    }

    override func configureHierarchy() {
        view.addSubview(tableView)
        view.addSubview(emptyLabel)
    }

    override func configureLayout() {
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        emptyLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(40)
        }
    }

    private func setupTableView() {
        tableView.register(
            DiaryTableViewCell.self,
            forCellReuseIdentifier: DiaryTableViewCell.identifier
        )

        // 고정 높이 설정 (화면 너비 기준)
        let screenWidth = UIScreen.main.bounds.width
        let cellHeight = (screenWidth - 32) * 0.5 + 16 // width - insets, height ratio 0.5, + vertical insets
        tableView.rowHeight = cellHeight
    }

    // MARK: - Binding
    private func bind() {
        DiaryManager.shared.observeDiaries(for: gameId)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] diaries in
                self?.diaries = diaries
                self?.tableView.reloadData()
                self?.emptyLabel.isHidden = !diaries.isEmpty
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Actions
    @objc private func addButtonTapped() {
        let createVC = CreateDiaryViewController(gameId: gameId)
        let navVC = UINavigationController(rootViewController: createVC)
        navVC.modalPresentationStyle = .fullScreen
        present(navVC, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension DiaryViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return diaries.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: DiaryTableViewCell.identifier,
            for: indexPath
        ) as? DiaryTableViewCell else {
            return UITableViewCell()
        }

        let diary = diaries[indexPath.row]
        cell.configure(with: diary)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension DiaryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let diary = diaries[indexPath.row]
        let detailVC = DiaryDetailViewController(diary: diary, gameId: gameId)
        navigationController?.pushViewController(detailVC, animated: true)
    }

    // 스와이프 액션 (수정/삭제)
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let diary = diaries[indexPath.row]

        // 삭제 액션
        let deleteAction = UIContextualAction(style: .destructive, title: "삭제") { [weak self] _, _, completionHandler in
            let confirmAlert = UIAlertController(
                title: "일기 삭제",
                message: "이 일기를 삭제하시겠습니까?",
                preferredStyle: .alert
            )
            confirmAlert.addAction(UIAlertAction(title: "취소", style: .cancel) { _ in
                completionHandler(false)
            })
            confirmAlert.addAction(UIAlertAction(title: "삭제", style: .destructive) { _ in
                _ = DiaryManager.shared.deleteDiary(diary)
                completionHandler(true)
            })
            self?.present(confirmAlert, animated: true)
        }
        deleteAction.backgroundColor = .systemRed
        deleteAction.image = UIImage(systemName: "trash.fill")

        // 수정 액션
        let editAction = UIContextualAction(style: .normal, title: L10n.edit) { [weak self] _, _, completionHandler in
            guard let self = self else {
                completionHandler(false)
                return
            }
            let createVC = CreateDiaryViewController(gameId: self.gameId, diary: diary)
            let navVC = UINavigationController(rootViewController: createVC)
            navVC.modalPresentationStyle = .fullScreen
            self.present(navVC, animated: true)
            completionHandler(true)
        }
        editAction.image = UIImage(systemName: "pencil")

        return UISwipeActionsConfiguration(actions: [deleteAction, editAction])
    }
}

// MARK: - DiaryTableViewCell
final class DiaryTableViewCell: UITableViewCell {
    static let identifier = "DiaryTableViewCell"

    private let cardView = {
        let view = UIView()
        view.backgroundColor = .label
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.1
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        return view
    }()

    private let monthLabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .systemBackground
        label.textAlignment = .center
        return label
    }()

    private let yearLabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .systemBackground
        label.textAlignment = .center
        return label
    }()

    private lazy var dateStackView = {
        let stackView = UIStackView(arrangedSubviews: [monthLabel, yearLabel])
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.alignment = .center
        return stackView
    }()

    private let titleLabel = {
        let label = UILabel()
        label.font = .Title.bold16
        label.textColor = .systemBackground
        label.numberOfLines = 1
        return label
    }()

    private let contentLabel = {
        let label = UILabel()
        label.font = .Body.regular14
        label.textColor = .systemBackground
        label.numberOfLines = 3
        return label
    }()

    private lazy var textStackView = {
        let stackView = UIStackView(arrangedSubviews: [titleLabel, contentLabel])
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.alignment = .leading
        return stackView
    }()

    private let mediaImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray5
        return imageView
    }()

    private let mediaContainerView = {
        let view = UIView()
        view.clipsToBounds = true
        return view
    }()

    private let playIconImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "play.circle.fill")
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        return imageView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(cardView)
        cardView.addSubview(dateStackView)
        cardView.addSubview(textStackView)
        cardView.addSubview(mediaContainerView)
        mediaContainerView.addSubview(mediaImageView)
        mediaImageView.addSubview(playIconImageView)

        cardView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(8)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        dateStackView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.equalTo(60)
        }

        textStackView.snp.makeConstraints { make in
            make.leading.equalTo(dateStackView.snp.trailing).offset(16)
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }

        mediaContainerView.snp.makeConstraints { make in
            make.leading.equalTo(dateStackView.snp.trailing).offset(16)
            make.trailing.top.bottom.equalToSuperview()
        }

        mediaImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        playIconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(48)
        }

        // mediaContainerView의 오른쪽 모서리만 둥글게
        mediaContainerView.layer.cornerRadius = 12
        mediaContainerView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
    }

    func configure(with diary: RealmDiary) {
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMM"
        let monthString = monthFormatter.string(from: diary.createdAt).uppercased()
        monthLabel.text = String(monthString.prefix(3))

        let yearFormatter = DateFormatter()
        yearFormatter.dateFormat = "yyyy"
        yearLabel.text = yearFormatter.string(from: diary.createdAt)

        titleLabel.text = diary.title
        contentLabel.text = diary.content

        // 미디어 처리 (첫 번째 미디어만 표시)
        if let firstMedia = diary.mediaItems.first,
           let mediaData = DiaryManager.shared.loadMediaFromDisk(relativePath: firstMedia.filePath) {

            if firstMedia.type == "video" {
                // 동영상 썸네일 생성
                if let thumbnail = generateVideoThumbnail(from: mediaData) {
                    mediaImageView.image = thumbnail
                    playIconImageView.isHidden = false
                }
            } else if firstMedia.type == "image" {
                // 이미지 표시
                mediaImageView.image = UIImage(data: mediaData)
                playIconImageView.isHidden = true
            }
            textStackView.isHidden = true
            mediaImageView.isHidden = false
        } else {
            // 미디어 없을 때 텍스트 표시
            textStackView.isHidden = false
            mediaImageView.isHidden = true
            playIconImageView.isHidden = true
        }
    }

    private func generateVideoThumbnail(from videoData: Data) -> UIImage? {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mov")
        do {
            try videoData.write(to: tempURL)
            let asset = AVAsset(url: tempURL)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true

            let cgImage = try imageGenerator.copyCGImage(at: .zero, actualTime: nil)
            try? FileManager.default.removeItem(at: tempURL)
            return UIImage(cgImage: cgImage)
        } catch {
            try? FileManager.default.removeItem(at: tempURL)
            return nil
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        monthLabel.text = nil
        yearLabel.text = nil
        titleLabel.text = nil
        contentLabel.text = nil
        mediaImageView.image = nil
        playIconImageView.isHidden = true
    }
}
