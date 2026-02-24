//
//  WidgetDataService.swift
//  GameFinder
//
//  Service for preparing and saving widget data
//  This file should ONLY be included in the App target (not Widget)
//

import Foundation
import Alamofire
import WidgetKit
import UIKit

// MARK: - Shared Widget Data Models (for App)
/// App과 Widget 간 공유되는 게임 데이터
struct SharedWidgetGame: Codable, Identifiable {
    let id: Int
    let title: String
    let platform: String
    let genre: String
    let releaseDate: Date
    let imageURL: String?
    let assetImageName: String?  // Assets에 있는 이미지 이름 (snapshot용)

    var localImageFileName: String? {
        imageURL != nil ? "game_\(id).jpg" : nil
    }

    /// GameDTO를 SharedWidgetGame으로 변환
    static func from(dto: GameDTO) -> SharedWidgetGame {
        let platformName = dto.platforms?.first?.platform.name ?? "Unknown"
        let genreNames = dto.genres?.prefix(2).map { $0.name }.joined(separator: ", ") ?? "Unknown"

        let releaseDate: Date
        if let releasedString = dto.released {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            releaseDate = formatter.date(from: releasedString) ?? Date()
        } else {
            releaseDate = Date()
        }

        return SharedWidgetGame(
            id: dto.id,
            title: dto.name,
            platform: platformName,
            genre: genreNames,
            releaseDate: releaseDate,
            imageURL: dto.backgroundImage,
            assetImageName: nil  // API 데이터는 Assets 이미지 없음
        )
    }
}

/// App Group에 저장되는 전체 위젯 데이터
struct SharedWidgetData: Codable {
    let games: [SharedWidgetGame]
    let lastUpdated: Date
}

// MARK: - App Group Manager (for App)
final class AppGroupManager {
    static let shared = AppGroupManager()

    private let groupIdentifier = "group.com.wkdtnwl.GameFinder"
    private let widgetDataKey = "widgetUpcomingGames"
    private let languageKey = "widgetLanguageCode"

    private init() {}

    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: groupIdentifier)
    }

    var sharedContainerURL: URL? {
        FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: groupIdentifier
        )
    }

    var widgetImagesDirectory: URL? {
        guard let container = sharedContainerURL else {
            print("[App-AppGroupManager] Shared container URL is nil")
            return nil
        }

        let directory = container.appendingPathComponent("WidgetImages")

        if !FileManager.default.fileExists(atPath: directory.path) {
            do {
                try FileManager.default.createDirectory(
                    at: directory,
                    withIntermediateDirectories: true
                )
            } catch {
                print("[App-AppGroupManager] Failed to create directory: \(error)")
            }
        }

        return directory
    }

    func saveWidgetData(_ data: SharedWidgetData) {
        guard let sharedDefaults = sharedDefaults else {
            print("[App-AppGroupManager] CRITICAL: Shared UserDefaults is nil!")
            print("   → UserDefaults(suiteName: \"\(groupIdentifier)\") returned nil")
            print("   → This means App Group is NOT properly configured")
            print("   → Check Xcode: Target → Signing & Capabilities → App Groups")
            return
        }
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let encoded = try encoder.encode(data)

            sharedDefaults.set(encoded, forKey: widgetDataKey)

        } catch {
            print("[App-AppGroupManager] Failed to encode: \(error)")
            print("   → Error details: \(error.localizedDescription)")
        }
    }

    func loadWidgetData() -> SharedWidgetData? {
        return loadWidgetDataInternal()
    }

    private func loadWidgetDataInternal() -> SharedWidgetData? {

        guard let sharedDefaults = sharedDefaults else {
            print("[App-AppGroupManager] Shared UserDefaults is nil!")
            return nil
        }
        
        guard let data = sharedDefaults.data(forKey: widgetDataKey) else {
            print("[App-AppGroupManager] No data found for key '\(widgetDataKey)'")
            print("   → This could mean:")
            print("      1. Data was never saved")
            print("      2. Different App Group ID between App and Widget")
            print("      3. UserDefaults was cleared")

            // 디버깅: 저장된 모든 키 출력
            let allKeys = Array(sharedDefaults.dictionaryRepresentation().keys)
            print("   → All keys in UserDefaults: \(allKeys)")

            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let decoded = try decoder.decode(SharedWidgetData.self, from: data)
            return decoded
        } catch {
            print("[App-AppGroupManager] Failed to decode: \(error)")
            print("   → Error details: \(error.localizedDescription)")
            return nil
        }
    }

    func saveImage(_ data: Data, fileName: String) -> Bool {
        guard let directory = widgetImagesDirectory else {
            print("[App-AppGroupManager] Images directory is nil")
            return false
        }

        let fileURL = directory.appendingPathComponent(fileName)

        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }

            try data.write(to: fileURL)
            return true
        } catch {
            print("[App-AppGroupManager] Failed to save image: \(error)")
            return false
        }
    }

    func resizeImage(_ image: UIImage, targetWidth: CGFloat = 280) -> UIImage? {
        let scale = targetWidth / image.size.width
        let targetHeight = image.size.height * scale
        let targetSize = CGSize(width: targetWidth, height: targetHeight)

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }

        return resizedImage
    }

    /// App Group에 언어 코드 저장
    func saveLanguage(_ languageCode: String) {
        guard let sharedDefaults = sharedDefaults else {
            print("[App-AppGroupManager] Cannot save language: UserDefaults is nil")
            return
        }

        sharedDefaults.set(languageCode, forKey: languageKey)
    }

    /// App Group에서 언어 코드 읽기
    func loadLanguage() -> String? {
        guard let sharedDefaults = sharedDefaults else {
            print("[App-AppGroupManager] Cannot load language: UserDefaults is nil")
            return nil
        }

        return sharedDefaults.string(forKey: languageKey)
    }
}

// MARK: - Widget Data Service
final class WidgetDataService {
    static let shared = WidgetDataService()

    private let legacyMockGameIDs: Set<Int> = [9999, 8888]

    private init() {}

    // MARK: - Test App Group with Mock Data
    /// 디버깅용: App Group이 정상 작동하는지 Mock 데이터로 테스트
#if DEBUG
    func testAppGroupWithMockData() {
        print("🧪 [WidgetDataService] Testing App Group with Mock data...")

        // App Group 접근 가능 여부 확인
        guard AppGroupManager.shared.sharedContainerURL != nil else {
            print("[WidgetDataService] CRITICAL: App Group container is nil!")
            print("   → Check if App Groups capability is enabled")
            print("   → Check if group ID matches: group.com.wkdtnwl.GameFinder")
            return
        }
        
        // Mock 데이터 생성
        let mockGames = [
            SharedWidgetGame(
                id: 9999,
                title: "Test Game 1 (Mock)",
                platform: "PlayStation 5",
                genre: "Action, RPG",
                releaseDate: Date().addingTimeInterval(60 * 60 * 24 * 30), // 30일 후
                imageURL: nil,
                assetImageName: nil
            ),
            SharedWidgetGame(
                id: 8888,
                title: "Test Game 2 (Mock)",
                platform: "Xbox Series X",
                genre: "Adventure, Shooter",
                releaseDate: Date().addingTimeInterval(60 * 60 * 24 * 60), // 60일 후
                imageURL: nil,
                assetImageName: nil
            )
        ]

        let mockData = SharedWidgetData(
            games: mockGames,
            lastUpdated: Date()
        )

        AppGroupManager.shared.saveWidgetData(mockData)

        // 저장 직후 다시 읽어서 검증
        if let loadedData = AppGroupManager.shared.loadWidgetData() {
            print("[WidgetDataService] VERIFICATION SUCCESS!")
            print("   → Games count: \(loadedData.games.count)")
            print("   → First game: \(loadedData.games.first?.title ?? "N/A")")
            print("   → Last updated: \(loadedData.lastUpdated)")
        } else {
            print("[WidgetDataService] VERIFICATION FAILED!")
            print("   → Data was saved but could not be read back")
        }

        // 위젯 새로고침
        WidgetCenter.shared.reloadAllTimelines()
    }
#endif

    // MARK: - Update Widget Data
    /// 앱에서 API를 호출하여 위젯용 데이터를 준비하고 App Group에 저장
    /// - Note: 이 메서드는 메인 앱에서만 호출해야 함 (위젯에서는 절대 네트워크 호출 금지)
    func updateWidgetData() async {
        // App Group 접근 가능 여부 먼저 확인
        guard AppGroupManager.shared.sharedContainerURL != nil else {
            print("[WidgetDataService] CRITICAL: App Group container is nil!")
            print("   → Cannot proceed without App Group access")
            return
        }

        // 과거 테스트 목데이터가 남아 있으면 정리
        purgeLegacyMockWidgetDataIfNeeded()

        do {
            // 1. API에서 출시 예정 게임 가져오기
            let upcomingGames = try await fetchUpcomingGamesFromAPI()
            // 2. SharedWidgetGame으로 변환
            var sharedGames: [SharedWidgetGame] = []

            for game in upcomingGames.prefix(10) { // 최대 10개만 저장 (메모리 절약)
                let sharedGame = SharedWidgetGame.from(dto: game)
                sharedGames.append(sharedGame)

                // 3. 이미지 다운로드 및 저장
                if let imageURL = game.backgroundImage,
                   let url = URL(string: imageURL),
                   let fileName = sharedGame.localImageFileName {
                    await downloadAndSaveImage(url: url, fileName: fileName)
                }
            }

            // 4. App Group에 데이터 저장
            let widgetData = SharedWidgetData(
                games: sharedGames,
                lastUpdated: Date()
            )
            AppGroupManager.shared.saveWidgetData(widgetData)

            // 5. 위젯 새로고침 요청
            WidgetCenter.shared.reloadAllTimelines()

        } catch {
            print("[WidgetDataService] Failed to update widget data: \(error)")
            print("   → Error details: \(error.localizedDescription)")
        }
    }

    /// 과거 디버깅용 테스트 데이터(9999/8888)가 저장되어 있으면 제거
    private func purgeLegacyMockWidgetDataIfNeeded() {
        guard let existingData = AppGroupManager.shared.loadWidgetData() else { return }

        let filteredGames = existingData.games.filter { !legacyMockGameIDs.contains($0.id) }
        guard filteredGames.count != existingData.games.count else { return }

        let cleanedData = SharedWidgetData(
            games: filteredGames,
            lastUpdated: Date()
        )
        AppGroupManager.shared.saveWidgetData(cleanedData)
        WidgetCenter.shared.reloadAllTimelines()

        print("[WidgetDataService] Removed legacy mock games from App Group")
        print("   → Before: \(existingData.games.count), After: \(filteredGames.count)")
    }

    // MARK: - Fetch Upcoming Games from API
    /// RAWG API에서 출시 예정 게임 목록 가져오기
    /// - Returns: GameDTO 배열
    private func fetchUpcomingGamesFromAPI() async throws -> [GameDTO] {
        // 3개월 후부터 6개월간의 출시 예정 게임
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .month, value: 3, to: Date()),
              let endDate = calendar.date(byAdding: .month, value: 6, to: startDate) else {
            throw URLError(.badURL)
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let start = dateFormatter.string(from: startDate)
        let end = dateFormatter.string(from: endDate)

        // RawgRouter를 사용하여 API 호출
        let router = RawgRouter.upcoming(start: start, end: end, page: 1, pageSize: 20)

        return try await withCheckedThrowingContinuation { continuation in
            AF.request(router)
                .validate()
                .responseDecodable(of: GameListDTO.self) { response in
                    switch response.result {
                    case .success(let gameListDTO):
                        continuation.resume(returning: gameListDTO.results)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
        }
    }

    // MARK: - Download and Save Image
    /// 이미지를 다운로드하여 App Group 컨테이너에 저장
    /// - Parameters:
    ///   - url: 다운로드할 이미지 URL
    ///   - fileName: 저장할 파일명
    private func downloadAndSaveImage(url: URL, fileName: String) async {
        do {
            // 이미지 다운로드
            let (data, _) = try await URLSession.shared.data(from: url)

            guard let originalImage = UIImage(data: data) else {
                print("[WidgetDataService] Failed to create image from data: \(fileName)")
                return
            }

            // 위젯 크기에 맞게 리사이즈 (메모리 절약)
            guard let resizedImage = AppGroupManager.shared.resizeImage(originalImage, targetWidth: 280),
                  let compressedData = resizedImage.jpegData(compressionQuality: 0.8) else {
                print("[WidgetDataService] Failed to resize image: \(fileName)")
                return
            }

            // App Group 컨테이너에 저장
            if !AppGroupManager.shared.saveImage(compressedData, fileName: fileName) {
                print("[WidgetDataService] Failed to save image: \(fileName)")
            }
        } catch {
            print("[WidgetDataService] Failed to download image: \(error)")
        }
    }
}
