//
//  DiaryManager.swift
//  GameFinder
//
//  Created by Claude on 10/6/25.
//

import Foundation
import RealmSwift
import RxSwift

final class DiaryManager {
    static let shared = DiaryManager()

    private let realm: Realm
    let diaryListChanged = PublishSubject<Int>() // gameId

    // 이미지/동영상 저장 디렉토리 경로
    private let diaryImagesDirectory: URL = {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let diaryImagesPath = documentsPath.appendingPathComponent("DiaryImages", isDirectory: true)

        // 디렉토리가 없으면 생성
        if !FileManager.default.fileExists(atPath: diaryImagesPath.path) {
            try? FileManager.default.createDirectory(at: diaryImagesPath, withIntermediateDirectories: true)
        }

        return diaryImagesPath
    }()

    private init() {
        do {
            realm = try Realm()
        } catch {
            fatalError("Realm initialization failed: \(error)")
        }
    }

    // MARK: - File Management

    /// 미디어 파일을 디스크에 저장하고 파일 경로 반환
    /// - Parameters:
    ///   - data: 저장할 이미지 또는 동영상 데이터
    ///   - type: "image" 또는 "video"
    /// - Returns: 저장된 파일의 상대 경로 (DiaryImages/UUID.jpg)
    private func saveMediaToDisk(data: Data, type: String) -> String? {
        let fileExtension = type == "image" ? "jpg" : "mov"
        let fileName = "\(UUID().uuidString).\(fileExtension)"
        let fileURL = diaryImagesDirectory.appendingPathComponent(fileName)

        do {
            try data.write(to: fileURL)
            // 상대 경로만 반환 (DiaryImages/UUID.jpg)
            return "DiaryImages/\(fileName)"
        } catch {
            print("Failed to save media file: \(error)")
            return nil
        }
    }

    /// 파일 경로로부터 미디어 데이터 로드
    /// - Parameter relativePath: 상대 경로 (DiaryImages/UUID.jpg)
    /// - Returns: 파일 데이터
    func loadMediaFromDisk(relativePath: String) -> Data? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(relativePath)

        return try? Data(contentsOf: fileURL)
    }

    /// 파일 삭제
    /// - Parameter relativePath: 상대 경로 (DiaryImages/UUID.jpg)
    private func deleteMediaFromDisk(relativePath: String) {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(relativePath)

        try? FileManager.default.removeItem(at: fileURL)
    }

    // MARK: - Create

    /// 일기 생성
    /// - Parameters:
    ///   - gameId: 게임 ID
    ///   - title: 제목
    ///   - content: 내용
    ///   - mediaItems: 미디어 아이템 배열 (이미지/동영상)
    /// - Returns: 성공 여부
    func createDiary(gameId: Int, title: String, content: String, mediaItems: [MediaItem]) -> Bool {
        do {
            try realm.write {
                let diary = RealmDiary(gameId: gameId, title: title, content: content)

                // 각 미디어를 디스크에 저장하고 경로를 Realm에 저장
                for mediaItem in mediaItems {
                    if let filePath = saveMediaToDisk(data: mediaItem.data, type: mediaItem.type) {
                        let realmMedia = RealmDiaryMedia(filePath: filePath, type: mediaItem.type)
                        diary.mediaItems.append(realmMedia)
                    }
                }

                realm.add(diary)

                // readingUpdatedAt 갱신
                if let game = realm.objects(RealmGame.self).where({ $0.gameId == gameId }).first {
                    game.readingUpdatedAt = Date()
                }
            }

            // 로깅 및 Analytics
            let gameName = realm.objects(RealmGame.self).where({ $0.gameId == gameId }).first?.name ?? "Unknown"
            LogManager.logCreateDiary(gameId: gameId, gameName: gameName, mediaCount: mediaItems.count)

            diaryListChanged.onNext(gameId)
            return true
        } catch {
            LogManager.error.error("Failed to create diary: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Read
    func getDiaries(for gameId: Int) -> [RealmDiary] {
        let diaries = realm.objects(RealmDiary.self)
            .where { $0.gameId == gameId }
            .sorted(byKeyPath: "createdAt", ascending: false)
        return Array(diaries)
    }

    func observeDiaries(for gameId: Int) -> Observable<[RealmDiary]> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onCompleted()
                return Disposables.create()
            }

            let results = self.realm.objects(RealmDiary.self)
                .where { $0.gameId == gameId }
                .sorted(byKeyPath: "createdAt", ascending: false)

            let token = results.observe { changes in
                switch changes {
                case .initial(let collection):
                    observer.onNext(Array(collection))
                case .update(let collection, _, _, _):
                    observer.onNext(Array(collection))
                case .error(let error):
                    observer.onError(error)
                }
            }

            return Disposables.create {
                token.invalidate()
            }
        }
    }

    // MARK: - Update

    /// 일기 수정
    /// - Parameters:
    ///   - diary: 수정할 일기 객체
    ///   - title: 새 제목
    ///   - content: 새 내용
    ///   - mediaItems: 새 미디어 아이템 배열
    /// - Returns: 성공 여부
    func updateDiary(diary: RealmDiary, title: String, content: String, mediaItems: [MediaItem]) -> Bool {
        let gameId = diary.gameId
        do {
            try realm.write {
                // 기존 미디어 파일 삭제
                for oldMedia in diary.mediaItems {
                    deleteMediaFromDisk(relativePath: oldMedia.filePath)
                }
                diary.mediaItems.removeAll()

                // 새 미디어 저장
                for mediaItem in mediaItems {
                    if let filePath = saveMediaToDisk(data: mediaItem.data, type: mediaItem.type) {
                        let realmMedia = RealmDiaryMedia(filePath: filePath, type: mediaItem.type)
                        diary.mediaItems.append(realmMedia)
                    }
                }

                diary.title = title
                diary.content = content
                diary.updatedAt = Date()

                // readingUpdatedAt 갱신
                if let game = realm.objects(RealmGame.self).where({ $0.gameId == diary.gameId }).first {
                    game.readingUpdatedAt = Date()
                }
            }

            // 로깅 및 Analytics
            LogManager.logUpdateDiary(gameId: gameId, mediaCount: mediaItems.count)

            diaryListChanged.onNext(diary.gameId)
            return true
        } catch {
            LogManager.error.error("Failed to update diary: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Delete

    /// 일기 삭제
    /// - Parameter diary: 삭제할 일기 객체
    /// - Returns: 성공 여부
    func deleteDiary(_ diary: RealmDiary) -> Bool {
        let gameId = diary.gameId
        do {
            try realm.write {
                // 미디어 파일 먼저 삭제
                for media in diary.mediaItems {
                    deleteMediaFromDisk(relativePath: media.filePath)
                }

                realm.delete(diary)

                // readingUpdatedAt 갱신
                if let game = realm.objects(RealmGame.self).where({ $0.gameId == gameId }).first {
                    game.readingUpdatedAt = Date()
                }
            }

            // 로깅 및 Analytics
            LogManager.logDeleteDiary(gameId: gameId)

            diaryListChanged.onNext(gameId)
            return true
        } catch {
            LogManager.error.error("Failed to delete diary: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Count
    func getDiaryCount(for gameId: Int) -> Int {
        return realm.objects(RealmDiary.self)
            .where { $0.gameId == gameId }
            .count
    }

    // MARK: - Delete All for Game

    /// 특정 게임의 모든 일기 삭제 (미디어 파일 포함)
    /// - Parameter gameId: 게임 ID
    /// - Returns: 성공 여부
    func deleteAllDiaries(for gameId: Int) -> Bool {
        let diaries = realm.objects(RealmDiary.self)
            .where { $0.gameId == gameId }

        guard !diaries.isEmpty else {
            return true // 삭제할 일기가 없으면 성공으로 처리
        }

        do {
            try realm.write {
                // 모든 미디어 파일 삭제
                for diary in diaries {
                    for media in diary.mediaItems {
                        deleteMediaFromDisk(relativePath: media.filePath)
                    }
                }

                // Realm에서 일기 삭제
                realm.delete(diaries)

                // readingUpdatedAt 갱신
                if let game = realm.objects(RealmGame.self).where({ $0.gameId == gameId }).first {
                    game.readingUpdatedAt = Date()
                }
            }

            // 로깅
            LogManager.database.info("🗑️ Deleted all diaries for game: \(gameId), count: \(diaries.count)")

            diaryListChanged.onNext(gameId)
            return true
        } catch {
            LogManager.error.error("Failed to delete all diaries for game: \(gameId) - \(error.localizedDescription)")
            return false
        }
    }
}
