//
//  AppGroupManager.swift
//  GameFinder
//
//  Manages data sharing between App and Widget Extension via App Groups
//  ⚠️ This file must be included in BOTH App and Widget Extension targets
//

import Foundation
import UIKit

// MARK: - App Group Manager
final class AppGroupManager {
    static let shared = AppGroupManager()

    // ⚠️ App Group Identifier - Xcode에서 설정한 것과 동일해야 함
    private let groupIdentifier = "group.com.wkdtnwl.GameFinder"
    private let widgetDataKey = "widgetUpcomingGames"

    private init() {}

    // MARK: - Shared UserDefaults
    /// App Group을 통해 공유되는 UserDefaults
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: groupIdentifier)
    }

    // MARK: - Shared Container URL
    /// App Group의 공유 컨테이너 디렉토리 URL
    var sharedContainerURL: URL? {
        FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: groupIdentifier
        )
    }

    // MARK: - Widget Images Directory
    /// 위젯 이미지를 저장할 App Group 내 디렉토리
    var widgetImagesDirectory: URL? {
        guard let container = sharedContainerURL else {
            print("⚠️ [AppGroupManager] Shared container URL is nil")
            return nil
        }

        let directory = container.appendingPathComponent("WidgetImages")

        // 디렉토리가 없으면 생성
        if !FileManager.default.fileExists(atPath: directory.path) {
            do {
                try FileManager.default.createDirectory(
                    at: directory,
                    withIntermediateDirectories: true
                )
                print("✅ [AppGroupManager] Created widget images directory: \(directory.path)")
            } catch {
                print("❌ [AppGroupManager] Failed to create directory: \(error)")
            }
        }

        return directory
    }

    // MARK: - Save Widget Data
    /// 위젯용 데이터를 App Group에 저장 (App에서 호출)
    /// - Parameter data: 저장할 SharedWidgetData
    func saveWidgetData(_ data: SharedWidgetData) {
        guard let sharedDefaults = sharedDefaults else {
            print("⚠️ [AppGroupManager] Shared UserDefaults not available")
            return
        }

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let encoded = try encoder.encode(data)
            sharedDefaults.set(encoded, forKey: widgetDataKey)
            sharedDefaults.synchronize()
            print("✅ [AppGroupManager] Widget data saved: \(data.games.count) games at \(data.lastUpdated)")
        } catch {
            print("❌ [AppGroupManager] Failed to encode widget data: \(error)")
        }
    }

    // MARK: - Load Widget Data
    /// App Group에서 위젯용 데이터 읽기 (Widget에서 호출)
    /// - Returns: 저장된 SharedWidgetData 또는 nil
    func loadWidgetData() -> SharedWidgetData? {
        guard let sharedDefaults = sharedDefaults else {
            print("⚠️ [AppGroupManager] Shared UserDefaults not available")
            return nil
        }

        guard let data = sharedDefaults.data(forKey: widgetDataKey) else {
            print("⚠️ [AppGroupManager] No widget data found")
            return nil
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let decoded = try decoder.decode(SharedWidgetData.self, from: data)
            print("✅ [AppGroupManager] Widget data loaded: \(decoded.games.count) games from \(decoded.lastUpdated)")
            return decoded
        } catch {
            print("❌ [AppGroupManager] Failed to decode widget data: \(error)")
            return nil
        }
    }

    // MARK: - Save Image
    /// 이미지를 App Group 컨테이너에 저장 (App에서 호출)
    /// - Parameters:
    ///   - data: 이미지 데이터
    ///   - fileName: 파일명 (예: "game_123.jpg")
    /// - Returns: 저장 성공 여부
    func saveImage(_ data: Data, fileName: String) -> Bool {
        guard let directory = widgetImagesDirectory else {
            print("⚠️ [AppGroupManager] Widget images directory is nil")
            return false
        }

        let fileURL = directory.appendingPathComponent(fileName)

        do {
            // 이미 존재하는 파일이면 삭제
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }

            try data.write(to: fileURL)
            print("✅ [AppGroupManager] Image saved: \(fileName) (\(data.count) bytes)")
            return true
        } catch {
            print("❌ [AppGroupManager] Failed to save image: \(error)")
            return false
        }
    }

    // MARK: - Load Image
    /// App Group 컨테이너에서 이미지 읽기 (Widget에서 호출)
    /// - Parameter fileName: 파일명 (예: "game_123.jpg")
    /// - Returns: 이미지 데이터 또는 nil
    func loadImage(fileName: String) -> Data? {
        guard let directory = widgetImagesDirectory else {
            print("⚠️ [AppGroupManager] Widget images directory is nil")
            return nil
        }

        let fileURL = directory.appendingPathComponent(fileName)

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("⚠️ [AppGroupManager] Image not found: \(fileName)")
            return nil
        }

        do {
            let data = try Data(contentsOf: fileURL)
            print("✅ [AppGroupManager] Image loaded: \(fileName) (\(data.count) bytes)")
            return data
        } catch {
            print("❌ [AppGroupManager] Failed to load image: \(error)")
            return nil
        }
    }

    // MARK: - Resize Image
    /// 이미지를 위젯에 적합한 크기로 리사이즈
    /// - Parameters:
    ///   - image: 원본 UIImage
    ///   - targetWidth: 목표 너비 (기본값: 400px, 위젯 Medium 크기 기준)
    /// - Returns: 리사이즈된 UIImage 또는 nil
    func resizeImage(_ image: UIImage, targetWidth: CGFloat = 400) -> UIImage? {
        let scale = targetWidth / image.size.width
        let targetHeight = image.size.height * scale
        let targetSize = CGSize(width: targetWidth, height: targetHeight)

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }

        return resizedImage
    }

    // MARK: - Clear Old Images
    /// 오래된 이미지 파일 정리 (선택사항)
    func clearOldImages() {
        guard let directory = widgetImagesDirectory else { return }

        do {
            let files = try FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.creationDateKey],
                options: .skipsHiddenFiles
            )

            // 30일 이상 된 파일 삭제
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!

            for file in files {
                let attributes = try FileManager.default.attributesOfItem(atPath: file.path)
                if let creationDate = attributes[.creationDate] as? Date,
                   creationDate < cutoffDate {
                    try FileManager.default.removeItem(at: file)
                    print("🗑️ [AppGroupManager] Deleted old image: \(file.lastPathComponent)")
                }
            }
        } catch {
            print("❌ [AppGroupManager] Failed to clear old images: \(error)")
        }
    }
}
