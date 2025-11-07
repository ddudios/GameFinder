//
//  CreateDiaryViewController.swift
//  GameFinder
//
//  Created by Suji Jang on 10/6/25.
//

import UIKit
import SnapKit
import PhotosUI
import AVFoundation

struct MediaItem {
    let data: Data
    let type: String // "image" or "video"
}

final class CreateDiaryViewController: BaseViewController {

    // MARK: - Properties
    private let gameId: Int
    private var diary: RealmDiary? // 수정 모드일 때 사용
    private var mediaItems: [MediaItem] = []
    private let createdDate: Date
    var onDiarySaved: (() -> Void)?

    // MARK: - UI Components
    private let scrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.keyboardDismissMode = .interactive
        return scrollView
    }()

    private let contentView = UIView()

    private let titleTextField = {
        let textField = UITextField()
        textField.placeholder = L10n.Diary.titlePlaceholder
        textField.font = .Title.bold20
        textField.borderStyle = .none
        textField.returnKeyType = .next
        return textField
    }()

    private let titleSeparator = {
        let view = UIView()
        view.backgroundColor = .separator
        return view
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
        return collectionView
    }()

    private let addMediaButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "plus.square.dashed"), for: .normal)
        button.tintColor = .secondaryLabel
        button.backgroundColor = .systemGray6
        button.layer.cornerRadius = 8
        return button
    }()

    private let contentTextView = {
        let textView = UITextView()
        textView.font = .Body.regular16
        textView.textColor = .label
        textView.backgroundColor = .clear
        textView.returnKeyType = .default
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        return textView
    }()

    private let placeholderLabel = {
        let label = UILabel()
        label.text = L10n.Diary.contentPlaceholder
        label.font = .Body.regular16
        label.textColor = .placeholderText
        return label
    }()

    // MARK: - Initialization
    init(gameId: Int, diary: RealmDiary? = nil) {
        self.gameId = gameId
        self.diary = diary
        self.createdDate = diary?.createdAt ?? Date()
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupActions()
        setupCollectionView()
        loadDiaryData()
        setupKeyboardHandling()
        setupTapGesture()
    }

    // MARK: - Setup
    private func setupNavigationBar() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy.MM.dd"
        navigationItem.title = dateFormatter.string(from: createdDate)

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: L10n.cancel,
            style: .plain,
            target: self,
            action: #selector(cancelButtonTapped)
        )

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: L10n.save,
            style: .done,
            target: self,
            action: #selector(saveButtonTapped)
        )
    }

    private func setupCollectionView() {
        mediaCollectionView.register(
            MediaCollectionViewCell.self,
            forCellWithReuseIdentifier: MediaCollectionViewCell.identifier
        )
    }

    override func configureHierarchy() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(titleTextField)
        contentView.addSubview(titleSeparator)
        contentView.addSubview(mediaCollectionView)
        contentView.addSubview(addMediaButton)
        contentView.addSubview(contentTextView)
        contentView.addSubview(placeholderLabel)
    }

    override func configureLayout() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView)
            make.width.equalTo(scrollView)
        }

        titleTextField.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(40)
        }

        titleSeparator.snp.makeConstraints { make in
            make.top.equalTo(titleTextField.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(1)
        }

        addMediaButton.snp.makeConstraints { make in
            make.top.equalTo(titleSeparator.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(20)
            make.size.equalTo(100)
        }

        mediaCollectionView.snp.makeConstraints { make in
            make.leading.equalTo(addMediaButton.snp.trailing).offset(8)
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalTo(addMediaButton)
            make.height.equalTo(100)
        }

        contentTextView.snp.makeConstraints { make in
            make.top.equalTo(addMediaButton.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.greaterThanOrEqualTo(300)
            make.bottom.equalToSuperview().inset(20)
        }

        placeholderLabel.snp.makeConstraints { make in
            make.top.leading.equalTo(contentTextView)
        }
    }

    override func configureView() {
        super.configureView()
    }

    private func setupActions() {
        titleTextField.delegate = self
        contentTextView.delegate = self
        addMediaButton.addTarget(self, action: #selector(addMediaButtonTapped), for: .touchUpInside)
    }

    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    private func loadDiaryData() {
        guard let diary = diary else { return }

        titleTextField.text = diary.title
        contentTextView.text = diary.content
        placeholderLabel.isHidden = !diary.content.isEmpty

        // 저장된 미디어 파일들을 로드
        for realmMedia in diary.mediaItems {
            if let data = DiaryManager.shared.loadMediaFromDisk(relativePath: realmMedia.filePath) {
                let mediaItem = MediaItem(data: data, type: realmMedia.type)
                mediaItems.append(mediaItem)
            }
        }
        mediaCollectionView.reloadData()
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

    // MARK: - Keyboard Handling
    private func setupKeyboardHandling() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let keyboardHeight = keyboardFrame.height

        scrollView.contentInset.bottom = keyboardHeight
        scrollView.verticalScrollIndicatorInsets.bottom = keyboardHeight
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        scrollView.contentInset.bottom = 0
        scrollView.verticalScrollIndicatorInsets.bottom = 0
    }

    // MARK: - Actions
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func cancelButtonTapped() {
        dismiss(animated: true)
    }

    @objc private func saveButtonTapped() {
        guard let title = titleTextField.text, !title.isEmpty else {
            showAlert(title: L10n.Diary.saveFailedAlertTitle, message: L10n.Diary.saveFailedAlertMessage)
            return
        }

        let content = contentTextView.text ?? ""

        let success: Bool
        if let diary = diary {
            // 수정 모드: 모든 미디어 아이템 저장
            success = DiaryManager.shared.updateDiary(
                diary: diary,
                title: title,
                content: content,
                mediaItems: mediaItems
            )
        } else {
            // 생성 모드: 모든 미디어 아이템 저장
            success = DiaryManager.shared.createDiary(
                gameId: gameId,
                title: title,
                content: content,
                mediaItems: mediaItems
            )
        }

        if success {
            dismiss(animated: true) {
                self.onDiarySaved?()
            }
        } else {
            showAlert(title: L10n.Diary.saveFailedAlertTitle, message: nil)
        }
    }

    @objc private func addMediaButtonTapped() {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 10 // 최대 10개
        configuration.filter = .any(of: [.images, .videos])

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    @objc private func removeMediaItem(at index: Int) {
        mediaItems.remove(at: index)
        mediaCollectionView.reloadData()
    }
}

// MARK: - UITextFieldDelegate
extension CreateDiaryViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        contentTextView.becomeFirstResponder()
        return true
    }
}

// MARK: - UITextViewDelegate
extension CreateDiaryViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        // 텍스트뷰가 키보드에 가려지지 않도록 스크롤 조정
        let textViewRect = textView.convert(textView.bounds, to: scrollView)
        scrollView.scrollRectToVisible(textViewRect, animated: true)
    }
}

// MARK: - UICollectionViewDataSource
extension CreateDiaryViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return mediaItems.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MediaCollectionViewCell.identifier,
            for: indexPath
        ) as? MediaCollectionViewCell else {
            return UICollectionViewCell()
        }

        let mediaItem = mediaItems[indexPath.item]
        cell.configure(with: mediaItem, index: indexPath.item)
        cell.onRemove = { [weak self] index in
            self?.removeMediaItem(at: index)
        }

        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension CreateDiaryViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 100, height: 100)
    }
}

// MARK: - PHPickerViewControllerDelegate
extension CreateDiaryViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard !results.isEmpty else { return }

        // DispatchGroup을 사용하여 비동기 로딩 작업 관리
        let group = DispatchGroup()

        for result in results {
            let itemProvider = result.itemProvider

            // 이미지 처리
            // 1. itemProvider가 UIImage 형태로 로드 가능한지 확인
            if itemProvider.canLoadObject(ofClass: UIImage.self) {
                group.enter()
                itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
                    defer { group.leave() }
                    guard let self = self, let image = object as? UIImage else { return }

                    // 2. UIImage를 JPEG 데이터로 변환 (압축률 0.8)
                    if let imageData = image.jpegData(compressionQuality: 0.8) {
                        let mediaItem = MediaItem(data: imageData, type: "image")
                        // 3. 메인 스레드에서 mediaItems 배열에 추가
                        DispatchQueue.main.async {
                            self.mediaItems.append(mediaItem)
                        }
                    }
                }
            }
            // 동영상 처리
            // 1. itemProvider가 동영상 파일인지 확인 (public.movie UTI)
            else if itemProvider.hasItemConformingToTypeIdentifier("public.movie") {
                group.enter()
                itemProvider.loadFileRepresentation(forTypeIdentifier: "public.movie") { [weak self] url, error in
                    defer { group.leave() }
                    guard let self = self, let url = url else { return }

                    do {
                        // 2. 임시 파일 경로에서 Data로 읽기
                        let videoData = try Data(contentsOf: url)
                        let mediaItem = MediaItem(data: videoData, type: "video")
                        // 3. 메인 스레드에서 mediaItems 배열에 추가
                        DispatchQueue.main.async {
                            self.mediaItems.append(mediaItem)
                        }
                    } catch {
                        print("Failed to load video: \(error)")
                    }
                }
            }
        }

        // 모든 미디어 로딩 완료 후 CollectionView 리로드
        group.notify(queue: .main) { [weak self] in
            self?.mediaCollectionView.reloadData()
        }
    }
}

// MARK: - MediaCollectionViewCell
final class MediaCollectionViewCell: UICollectionViewCell {

    var onRemove: ((Int) -> Void)?
    private var currentIndex: Int = 0

    private let imageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.backgroundColor = .systemGray6
        return imageView
    }()

    private let removeButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = .systemRed
        button.backgroundColor = .white
        button.layer.cornerRadius = 10
        return button
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
        contentView.addSubview(removeButton)

        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        playIconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(30)
        }

        removeButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(4)
            make.trailing.equalToSuperview().offset(-4)
            make.size.equalTo(20)
        }

        removeButton.addTarget(self, action: #selector(removeButtonTapped), for: .touchUpInside)
    }

    /// 미디어 아이템으로 셀 구성
    /// - Parameters:
    ///   - mediaItem: 이미지 또는 동영상 데이터
    ///   - index: 미디어 배열에서의 인덱스 (삭제 시 사용)
    func configure(with mediaItem: MediaItem, index: Int) {
        currentIndex = index

        if mediaItem.type == "image" {
            // 이미지: Data를 UIImage로 변환하여 표시
            imageView.image = UIImage(data: mediaItem.data)
            playIconImageView.isHidden = true
        } else if mediaItem.type == "video" {
            // 동영상: 첫 프레임을 썸네일로 생성하여 표시
            let thumbnail = generateVideoThumbnail(from: mediaItem.data)
            imageView.image = thumbnail
            playIconImageView.isHidden = false
        }
    }

    /// 동영상 데이터에서 썸네일 이미지 생성
    /// - Parameter videoData: 동영상 파일 데이터
    /// - Returns: 동영상 첫 프레임의 UIImage (실패 시 nil)
    private func generateVideoThumbnail(from videoData: Data) -> UIImage? {
        // 1. 임시 디렉토리에 동영상 파일 저장
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mov")
        do {
            try videoData.write(to: tempURL)

            // 2. AVAsset으로 동영상 로드
            let asset = AVAsset(url: tempURL)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true // 회전 정보 적용

            // 3. 첫 프레임(time: .zero)에서 이미지 추출
            let cgImage = try imageGenerator.copyCGImage(at: .zero, actualTime: nil)

            // 4. 임시 파일 삭제
            try? FileManager.default.removeItem(at: tempURL)
            return UIImage(cgImage: cgImage)
        } catch {
            try? FileManager.default.removeItem(at: tempURL)
            return nil
        }
    }

    @objc private func removeButtonTapped() {
        onRemove?(currentIndex)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        playIconImageView.isHidden = true
    }
}
