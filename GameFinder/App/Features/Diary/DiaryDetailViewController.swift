//
//  DiaryDetailViewController.swift
//  GameFinder
//
//  Created by Claude on 10/6/25.
//

import UIKit
import SnapKit
import AVFoundation
import AVKit

final class DiaryDetailViewController: BaseViewController {

    // MARK: - Properties
    private let diary: RealmDiary
    private let gameId: Int
    private var mediaItems: [MediaItem] = []

    // MARK: - UI Components
    private let scrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()

    private let contentView = UIView()

    private let dateLabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()

    private let titleLabel = {
        let label = UILabel()
        label.font = .Title.bold24
        label.textColor = .label
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()

    private lazy var mediaCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isPagingEnabled = true
        return collectionView
    }()

    private let pageControl = {
        let pageControl = UIPageControl()
        pageControl.currentPageIndicatorTintColor = .label
        pageControl.pageIndicatorTintColor = .systemGray4
        pageControl.hidesForSinglePage = true
        return pageControl
    }()

    private let contentTextView = {
        let textView = UITextView()
        textView.font = .Body.regular16
        textView.textColor = .label
        textView.backgroundColor = .clear
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        return textView
    }()

    // MARK: - Initialization
    init(diary: RealmDiary, gameId: Int) {
        self.diary = diary
        self.gameId = gameId
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
        loadDiaryData()
    }

    // MARK: - Setup
    private func setupNavigationBar() {
        navigationItem.largeTitleDisplayMode = .never

        let editButton = UIBarButtonItem(
            image: UIImage(systemName: "pencil"),
            style: .plain,
            target: self,
            action: #selector(editButtonTapped)
        )

        let deleteButton = UIBarButtonItem(
            image: UIImage(systemName: "trash"),
            style: .plain,
            target: self,
            action: #selector(deleteButtonTapped)
        )

        navigationItem.rightBarButtonItems = [editButton, deleteButton]
    }

    private func setupCollectionView() {
        mediaCollectionView.register(
            DiaryMediaCell.self,
            forCellWithReuseIdentifier: DiaryMediaCell.identifier
        )
    }

    override func configureHierarchy() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(mediaCollectionView)
        contentView.addSubview(pageControl)
        contentView.addSubview(titleLabel)
        contentView.addSubview(dateLabel)
        contentView.addSubview(contentTextView)
    }

    override func configureLayout() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView)
            make.width.equalTo(scrollView)
        }

        mediaCollectionView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(300)
        }

        pageControl.snp.makeConstraints { make in
            make.top.equalTo(mediaCollectionView.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(pageControl.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
        }

        dateLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(20)
        }

        contentTextView.snp.makeConstraints { make in
            make.top.equalTo(dateLabel.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().inset(20)
        }
    }

    private func loadDiaryData() {
        // 날짜 포맷
        let dateFormatter = DateFormatter()
        dateFormatter.setLocalizedDateFormatFromTemplate("yyyyMMMMdEEEE")
        dateFormatter.locale = Locale.current
        dateLabel.text = dateFormatter.string(from: diary.createdAt)

        // 제목
        titleLabel.text = diary.title

        // 내용
        contentTextView.text = diary.content

        // 미디어 로드
        for realmMedia in diary.mediaItems {
            if let data = DiaryManager.shared.loadMediaFromDisk(relativePath: realmMedia.filePath) {
                let mediaItem = MediaItem(data: data, type: realmMedia.type)
                mediaItems.append(mediaItem)
            }
        }

        // 미디어가 없으면 컬렉션뷰와 페이지 컨트롤 숨김
        if mediaItems.isEmpty {
            mediaCollectionView.isHidden = true
            pageControl.isHidden = true

            mediaCollectionView.snp.updateConstraints { make in
                make.height.equalTo(0)
            }

            pageControl.snp.updateConstraints { make in
                make.top.equalTo(mediaCollectionView.snp.bottom).offset(0)
            }

            titleLabel.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(20)
                make.leading.trailing.equalToSuperview().inset(20)
            }
        } else {
            pageControl.numberOfPages = mediaItems.count
            mediaCollectionView.reloadData()
        }
    }

    // MARK: - Actions
    @objc private func editButtonTapped() {
        let createVC = CreateDiaryViewController(gameId: gameId, diary: diary)
        createVC.onDiarySaved = { [weak self] in
            self?.reloadDiaryData()
        }
        let navVC = UINavigationController(rootViewController: createVC)
        navVC.modalPresentationStyle = .fullScreen
        present(navVC, animated: true)
    }

    private func reloadDiaryData() {
        mediaItems.removeAll()
        loadDiaryData()
        mediaCollectionView.reloadData()
    }

    @objc private func deleteButtonTapped() {
        let confirmAlert = UIAlertController(
            title: L10n.Diary.deleteAlertTitle,
            message: L10n.Diary.deleteLogAlertMessage,
            preferredStyle: .alert
        )
        confirmAlert.addAction(UIAlertAction(title: L10n.cancel, style: .cancel))
        confirmAlert.addAction(UIAlertAction(title: L10n.delete, style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            if DiaryManager.shared.deleteDiary(self.diary) {
                self.navigationController?.popViewController(animated: true)
            }
        })
        present(confirmAlert, animated: true)
    }

    private func showFullscreenImage(mediaItem: MediaItem) {
        guard let image = UIImage(data: mediaItem.data) else { return }
        let fullscreenVC = FullscreenImageViewController(image: image)
        fullscreenVC.modalPresentationStyle = .overFullScreen
        present(fullscreenVC, animated: true)
    }

    private func playFullscreenVideo(mediaItem: MediaItem) {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mov")
        do {
            try mediaItem.data.write(to: tempURL)
            let player = AVPlayer(url: tempURL)
            let playerVC = AVPlayerViewController()
            playerVC.player = player
            present(playerVC, animated: true) {
                player.play()
            }
        } catch {
            print("Failed to load video: \(error)")
        }
    }
}

// MARK: - UICollectionViewDataSource
extension DiaryDetailViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return mediaItems.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: DiaryMediaCell.identifier,
            for: indexPath
        ) as? DiaryMediaCell else {
            return UICollectionViewCell()
        }

        let mediaItem = mediaItems[indexPath.item]
        cell.configure(with: mediaItem)

        // 이미지 탭 콜백
        cell.onImageTapped = { [weak self] in
            self?.showFullscreenImage(mediaItem: mediaItem)
        }

        // 비디오 탭 콜백
        cell.onVideoTapped = { [weak self] in
            self?.playFullscreenVideo(mediaItem: mediaItem)
        }

        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension DiaryDetailViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 300)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .zero
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}

// MARK: - UIScrollViewDelegate
extension DiaryDetailViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == mediaCollectionView {
            let pageWidth = mediaCollectionView.bounds.width
            let currentPage = Int((mediaCollectionView.contentOffset.x + pageWidth / 2) / pageWidth)
            pageControl.currentPage = currentPage
        }
    }
}

// MARK: - DiaryMediaCell
final class DiaryMediaCell: UICollectionViewCell {

    var onImageTapped: (() -> Void)?
    var onVideoTapped: (() -> Void)?
    private var currentMediaType: String?

    private let imageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray6
        return imageView
    }()

    private let playIconImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "play.circle.fill")
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        return imageView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(imageView)
        contentView.addSubview(playIconImageView)

        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        playIconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(60)
        }

        // 이미지 탭 제스처
        let imageTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(imageTapGesture)

        // 비디오 play icon 탭 제스처
        let videoTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        playIconImageView.isUserInteractionEnabled = true
        playIconImageView.addGestureRecognizer(videoTapGesture)
    }

    @objc private func handleTap() {
        if currentMediaType == "image" {
            onImageTapped?()
        } else if currentMediaType == "video" {
            onVideoTapped?()
        }
    }

    func configure(with mediaItem: MediaItem) {
        currentMediaType = mediaItem.type
        if mediaItem.type == "image" {
            imageView.image = UIImage(data: mediaItem.data)
            playIconImageView.isHidden = true
        } else if mediaItem.type == "video" {
            let thumbnail = generateVideoThumbnail(from: mediaItem.data)
            imageView.image = thumbnail
            playIconImageView.isHidden = false
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
        imageView.image = nil
        playIconImageView.isHidden = true
        currentMediaType = nil
    }
}

// MARK: - FullscreenImageViewController
final class FullscreenImageViewController: UIViewController {

    private let image: UIImage
    private var initialCenter: CGPoint = .zero

    private let scrollView = {
        let scrollView = UIScrollView()
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 3.0
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }()

    private let imageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        return imageView
    }()

    private let closeButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        button.layer.cornerRadius = 20
        return button
    }()

    init(image: UIImage) {
        self.image = image
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupUI()
        imageView.image = image
    }

    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        view.addSubview(closeButton)

        scrollView.delegate = self

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.height.equalTo(scrollView)
        }

        closeButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.leading.equalToSuperview().offset(16)
            make.size.equalTo(40)
        }

        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)

        // 배경 탭 제스처 추가
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)

        // 스와이프 다운 제스처 추가
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        panGesture.delegate = self
        view.addGestureRecognizer(panGesture)
    }

    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }

    @objc private func backgroundTapped() {
        dismiss(animated: true)
    }

    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)

        switch gesture.state {
        case .began:
            initialCenter = view.center

        case .changed:
            // 아래로만 드래그 허용
            if translation.y > 0 {
                view.center = CGPoint(x: initialCenter.x, y: initialCenter.y + translation.y)
                // 드래그 거리에 따라 배경 투명도 조정
                let progress = min(translation.y / 200, 1.0)
                view.backgroundColor = UIColor.black.withAlphaComponent(1.0 - progress)
            }

        case .ended, .cancelled:
            // 충분히 아래로 드래그했거나 빠른 속도로 스와이프한 경우 dismiss
            if translation.y > 100 || velocity.y > 500 {
                dismiss(animated: true)
            } else {
                // 원래 위치로 복귀
                UIView.animate(withDuration: 0.3) {
                    self.view.center = self.initialCenter
                    self.view.backgroundColor = .black
                }
            }

        default:
            break
        }
    }
}

// MARK: - UIScrollViewDelegate
extension FullscreenImageViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}

// MARK: - UIGestureRecognizerDelegate
extension FullscreenImageViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Tap gesture의 경우: imageView나 closeButton이 아닌 배경을 탭한 경우에만 제스처 수신
        if gestureRecognizer is UITapGestureRecognizer {
            return touch.view == view || touch.view == scrollView
        }
        // Pan gesture의 경우: zoom이 1.0일 때만 동작
        if gestureRecognizer is UIPanGestureRecognizer {
            return scrollView.zoomScale == 1.0
        }
        return true
    }
}
