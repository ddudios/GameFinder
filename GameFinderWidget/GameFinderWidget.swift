//
//  GameFinderWidget.swift
//  GameFinderWidget
//
//  Created by Suji Jang on 12/12/25.
//

import WidgetKit
import SwiftUI

// MARK: - Shared Widget Data Models
/// App과 Widget 간 공유되는 게임 데이터
struct SharedWidgetGame: Codable, Identifiable {
    let id: Int
    let title: String
    let platform: String
    let genre: String
    let releaseDate: Date
    let imageURL: String?
    let assetImageName: String?

    /// App Group 컨테이너에 저장된 로컬 이미지 파일명
    var localImageFileName: String? {
        imageURL != nil ? "game_\(id).jpg" : nil
    }

    static var mockData = SharedWidgetGame(
        id: 1,
        title: "Ethereal Shards",
        platform: "PlayStation",
        genre: "Action, RPG",
        releaseDate: Date(),
        imageURL: nil,
        assetImageName: "EtherealShards"
    )
}

/// App Group에 저장되는 전체 위젯 데이터
struct SharedWidgetData: Codable {
    let games: [SharedWidgetGame]
    let lastUpdated: Date
}

// MARK: - App Group Manager
/// App과 Widget 간 데이터 공유 관리
final class AppGroupManager {
    static let shared = AppGroupManager()

    private let groupIdentifier = "group.com.wkdtnwl.GameFinder"
    private let widgetDataKey = "widgetUpcomingGames"
    private let languageKey = "widgetLanguageCode"

    private init() {}

    /// Shared UserDefaults
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: groupIdentifier)
    }

    /// Shared Container URL
    var sharedContainerURL: URL? {
        FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: groupIdentifier
        )
    }

    /// Widget Images Directory
    var widgetImagesDirectory: URL? {
        guard let container = sharedContainerURL else {
            print("⚠️ [Widget-AppGroupManager] Shared container URL is nil")
            return nil
        }
        let directory = container.appendingPathComponent("WidgetImages")
        return directory
    }

    /// App Group에서 위젯 데이터 읽기
    func loadWidgetData() -> SharedWidgetData? {
        guard let sharedDefaults = sharedDefaults else {
            print("[Widget-AppGroupManager] CRITICAL: Shared UserDefaults is nil!")
            print("   → UserDefaults(suiteName: \"\(groupIdentifier)\") returned nil")
            print("   → This means App Group is NOT properly configured in Widget")
            print("   → Check Xcode: GameFinderWidgetExtension → Signing & Capabilities → App Groups")
            return nil
        }

        guard let data = sharedDefaults.data(forKey: widgetDataKey) else {
            print("[Widget-AppGroupManager] No data found for key '\(widgetDataKey)'")
            print("   → Possible reasons:")
            print("      1. App hasn't saved data yet (run the main app first)")
            print("      2. Different App Group ID between App and Widget")
            print("      3. Data was saved but under a different key")

            // 디버깅: 저장된 모든 키 출력
            let allKeys = Array(sharedDefaults.dictionaryRepresentation().keys)
            print("   → All keys in UserDefaults: \(allKeys)")

            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let decoded = try decoder.decode(SharedWidgetData.self, from: data)
            
            if let firstGame = decoded.games.first {
                print("   → First game: \(firstGame.title)")
            }
            return decoded
        } catch {
            print("[Widget-AppGroupManager] Failed to decode: \(error)")
            print("   → Error details: \(error.localizedDescription)")
            return nil
        }
    }

    /// App Group에서 이미지 읽기
    func loadImage(fileName: String) -> Data? {
        guard let directory = widgetImagesDirectory else {
            print("[Widget-AppGroupManager] Images directory is nil")
            return nil
        }

        let fileURL = directory.appendingPathComponent(fileName)

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("[Widget-AppGroupManager] Image not found: \(fileName)")
            return nil
        }

        do {
            let data = try Data(contentsOf: fileURL)
            return data
        } catch {
            print("[Widget-AppGroupManager] Failed to load image: \(error)")
            return nil
        }
    }

    /// App Group에서 언어 코드 읽기
    func loadLanguage() -> String? {
        guard let sharedDefaults = sharedDefaults else {
            print("[Widget-AppGroupManager] Cannot load language: UserDefaults is nil")
            return nil
        }

        return sharedDefaults.string(forKey: languageKey)
    }
}

// MARK: - Localization Helper
/// 특정 언어의 로컬라이징된 문자열을 가져오는 함수
func localizedString(_ key: String, languageCode: String?) -> String {
    guard let languageCode = languageCode,
          let bundlePath = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
          let bundle = Bundle(path: bundlePath) else {
        // 언어 코드가 없거나 번들을 찾을 수 없으면 시스템 언어 사용
        return NSLocalizedString(key, comment: "")
    }

    return NSLocalizedString(key, bundle: bundle, comment: "")
}

// MARK: - Date Formatter (메모리 절약을 위해 재사용)
private let widgetDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .long  // 긴 날짜 형식
    formatter.timeStyle = .none
    return formatter
}()

/// 날짜를 언어별 긴 형식으로 포맷팅
/// - en: "April 1, 2025"
/// - ko: "2025년 4월 1일"
/// - ja: "2025年4月1日"
func formatReleaseDate(_ date: Date, languageCode: String?) -> String {
    // 언어에 맞는 locale 설정
    if let languageCode = languageCode {
        widgetDateFormatter.locale = Locale(identifier: languageCode)
    } else {
        widgetDateFormatter.locale = Locale.current
    }
    return widgetDateFormatter.string(from: date)
}

// MARK: - Daily Shuffle Entry
struct DailyShuffleEntry: TimelineEntry {
    let date: Date
    let game: SharedWidgetGame? // App Group에서 읽은 실제 데이터
    let languageCode: String? // 앱에서 설정한 언어 코드
    let isPlaceholder: Bool
}

// MARK: - Timeline Provider
struct Provider: AppIntentTimelineProvider {

    // MARK: Placeholder
    /// 위젯이 처음 추가될 때 보여줄 플레이스홀더
    /// 즉시 반환해야 함 - 네트워크 호출 금지
    func placeholder(in context: Context) -> DailyShuffleEntry {
        let languageCode = AppGroupManager.shared.loadLanguage()
        return DailyShuffleEntry(
            date: Date(),
            game: nil, // 플레이스홀더는 빈 상태
            languageCode: languageCode,
            isPlaceholder: true
        )
    }

    // MARK: Snapshot
    /// 위젯 갤러리에서 미리보기로 보여줄 스냅샷
    /// 즉시 반환해야 함 - 네트워크 호출 금지
    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> DailyShuffleEntry {
        let languageCode = AppGroupManager.shared.loadLanguage()
        return DailyShuffleEntry(
            date: Date(),
            game: SharedWidgetGame.mockData,
            languageCode: languageCode,
            isPlaceholder: false
        )
    }

    // MARK: Timeline
    /// 위젯에 표시할 타임라인 생성
    /// 네트워크 호출 금지 - App Group에서 데이터만 읽기
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<DailyShuffleEntry> {
        var entries: [DailyShuffleEntry] = []

        // App Group에서 언어 코드 읽기
        let languageCode = AppGroupManager.shared.loadLanguage()

        // App Group에서 저장된 데이터 읽기 (로컬 읽기만 - 네트워크 호출 없음)
        if let sharedData = AppGroupManager.shared.loadWidgetData() {
            // 오늘의 타임라인 생성 (메모리 절약을 위해 1개만)
            let calendar = Calendar.current
            let now = Date()

            if let startOfDay = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: now),
               let randomGame = sharedData.games.randomElement() {

                let entry = DailyShuffleEntry(
                    date: startOfDay,
                    game: randomGame,
                    languageCode: languageCode,
                    isPlaceholder: false
                )
                entries.append(entry)
            }
        } else {
            print("[Widget] No data found in App Group - showing empty state")
        }

        // 데이터가 없으면 빈 상태 표시
        if entries.isEmpty {
            entries.append(DailyShuffleEntry(
                date: Date(),
                game: nil,
                languageCode: languageCode,
                isPlaceholder: false
            ))
        }

        // 다음 업데이트: 내일 자정
        let nextUpdate = Calendar.current.startOfDay(for: Date())
            .addingTimeInterval(60 * 60 * 24)

        return Timeline(entries: entries, policy: .after(nextUpdate))
    }
}

struct GameFinderWidgetEntryView : View {
    var entry: DailyShuffleEntry

    var body: some View {
        Group {
            if let game = entry.game {
                // App Group에서 읽은 데이터가 있을 때
                contentView(game: game)
            } else {
                // 데이터가 없을 때 (앱을 아직 실행하지 않은 경우)
                emptyStateView
            }
        }
        .redacted(reason: entry.isPlaceholder ? .placeholder : [])
    }

    private var emptyStateView: some View {
        ZStack {
            Image("appIcon_v2")
                .resizable()
                .scaledToFill()
                .scaleEffect(2.3)
                .overlay(Color.black.opacity(0.4))

            VStack(alignment: .leading, spacing: 8) {
                Text(localizedString("widget_title", languageCode: entry.languageCode))
                    .font(.headline)
                    .foregroundColor(.white)

                Divider()
                    .background(Color.white)

                Text(localizedString("widget_empty_message", languageCode: entry.languageCode))
                    .foregroundColor(.white)
            }
            .padding(24)
        }
    }

    private func contentView(game: SharedWidgetGame) -> some View {
        Link(destination: URL(string: "gamefinder://game/\(game.id)")!) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(localizedString("widget_title", languageCode: entry.languageCode))
                        .font(.headline)
                    Divider()

                    VStack(alignment: .leading, spacing: 4) {
                        Text(game.title)
                            .font(.body)
                            .lineLimit(1)

                        Text({
                            let dateString = formatReleaseDate(game.releaseDate, languageCode: entry.languageCode)
                            let releasePrefix = localizedString("widget_release_prefix", languageCode: entry.languageCode)
                            return "\(releasePrefix) \(dateString)"
                        }())
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)

                        // 플랫폼이 Unknown이 아닐 때만 표시
                        if game.platform != "Unknown" {
                            Text(game.platform)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }

                        // 장르가 Unknown이 아닐 때만 표시
                        if game.genre != "Unknown" {
                            Text(game.genre)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                .padding(.leading, 24)

                // 이미지 로드 우선순위: Assets → App Group → noImage
                Group {
                    if let assetName = game.assetImageName {
                        // 1. Assets에 있는 이미지 (snapshot용)
                        Image(assetName)
                            .resizable()
                            .scaledToFill()
                    } else if let fileName = game.localImageFileName,
                              let imageData = AppGroupManager.shared.loadImage(fileName: fileName),
                              let uiImage = UIImage(data: imageData) {
                        // 2. App Group에 저장된 다운로드 이미지
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        // 3. 기본 이미지
                        Image("noImage")
                            .resizable()
                            .scaledToFill()
                    }
                }
                .frame(width: 140)
                .clipped()
            }
        }
    }
}

struct GameFinderWidget: Widget {
    let kind: String = "GameFinderWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            GameFinderWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .contentMarginsDisabled()
        .description("출시 예정 게임을 추천받습니다.")
        .supportedFamilies([.systemMedium])
    }
}

#Preview(as: .systemMedium) {
    GameFinderWidget()
} timeline: {
    DailyShuffleEntry(
        date: .now,
        game: SharedWidgetGame(
            id: 1,
            title: "Ethereal Shards",
            platform: "PlayStation",
            genre: "Action, RPG",
            releaseDate: Date(),
            imageURL: nil,
            assetImageName: "EtherealShards"
        ),
        languageCode: "ko",
        isPlaceholder: false
    )
}
