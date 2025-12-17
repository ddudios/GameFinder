//
//  GameFinderWidget.swift
//  GameFinderWidget
//
//  Created by Suji Jang on 12/12/25.
//

import WidgetKit
import SwiftUI

// MARK: - Widget Game Model
struct WidgetGame: Identifiable {
    let id: Int
    let title: String
    let coverImagePath: String? // 로컬 에셋 이름
    let imageURL: String? // 원격 이미지 URL
    let platform: String
    let genre: String
    let releaseDate: Date

    static var mockData: [WidgetGame] {
        [
            WidgetGame(id: 1, title: "Ethereal Shards", coverImagePath: "EtherealShards", imageURL: nil, platform: "PlayStation", genre: "Action, RPG", releaseDate: Date())
        ]
    }
}

// MARK: - Daily Shuffle Entry
struct DailyShuffleEntry: TimelineEntry {
    let date: Date
    let games: [WidgetGame]
    let isPlaceholder: Bool
}

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> DailyShuffleEntry {
        DailyShuffleEntry(
            date: Date(),
            games: WidgetGame.mockData,
            isPlaceholder: true
        )
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> DailyShuffleEntry {
        DailyShuffleEntry(
            date: Date(),
            games: WidgetGame.mockData,
            isPlaceholder: false
        )
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<DailyShuffleEntry> {
        var games: [WidgetGame] = []

        do {
            // API에서 출시 예정 게임 가져오기
            let upcomingGames = try await WidgetNetworkManager.shared.fetchUpcomingGames()

            // 랜덤으로 1개 선택
            if var randomGame = upcomingGames.randomElement() {
                // 이미지가 있으면 다운로드하여 로컬에 저장
                if let imageURL = randomGame.imageURL {
                    let localPath = await WidgetNetworkManager.shared.downloadAndSaveImage(
                        from: imageURL,
                        gameId: randomGame.id
                    )
                    // 로컬 경로를 coverImagePath에 저장
                    randomGame = WidgetGame(
                        id: randomGame.id,
                        title: randomGame.title,
                        coverImagePath: localPath,
                        imageURL: randomGame.imageURL,
                        platform: randomGame.platform,
                        genre: randomGame.genre,
                        releaseDate: randomGame.releaseDate
                    )
                }
                games = [randomGame]
            }
        } catch {
            print("Failed to fetch upcoming games: \(error)")
            // 에러 발생 시 빈 배열 사용
            games = []
        }

        let entry = DailyShuffleEntry(
            date: Date(),
            games: games,
            isPlaceholder: false
        )

        // 매일 자정에 업데이트
        let nextUpdate = Calendar.current.startOfDay(for: Date())
            .addingTimeInterval(60 * 60 * 24)

        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
}

struct GameFinderWidgetEntryView : View {
    var entry: DailyShuffleEntry

    var body: some View {
        Group {
            if entry.games.isEmpty && !entry.isPlaceholder {
                // 데이터가 없을 때 (로딩 실패)
                emptyStateView
            } else {
                // 데이터가 있을 때 또는 placeholder일 때
                contentView
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
                Text(L10n.Widget.title)
                    .font(.headline)
                    .foregroundColor(.white)

                Divider()
                    .background(Color.white)

                Text("새로운 게임을 찾아 보세요!")
                    .foregroundColor(.white)
            }
            .padding(24)
        }
    }

    private var contentView: some View {
        Link(destination: URL(string: "gamefinder://game/\(entry.games.first?.id ?? 0)")!) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.Widget.title)
                        .font(.headline)
                    Divider()

                    ForEach(entry.games) { game in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(game.title)
                                .font(.body)
                                .lineLimit(1)
                            Text({
                                let formatter = DateFormatter()
                                formatter.dateStyle = .long
                                formatter.timeStyle = .none
                                let dateString = formatter.string(from: game.releaseDate)
                                return L10n.Widget.release.localized(with: dateString)
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
                }
                .padding(.leading, 24)

                // 이미지 표시: 로컬 파일 경로 -> 로컬 에셋 -> noImage 순서
                Group {
                    if let coverImagePath = entry.games.first?.coverImagePath,
                       FileManager.default.fileExists(atPath: coverImagePath),
                       let uiImage = UIImage(contentsOfFile: coverImagePath) {
                        // 로컬에 저장된 이미지 파일 사용
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    } else if let coverImagePath = entry.games.first?.coverImagePath,
                              !coverImagePath.contains("/") {
                        // Assets에 있는 이미지 사용 (경로가 아닌 이름만 있는 경우)
                        Image(coverImagePath)
                            .resizable()
                            .scaledToFill()
                    } else {
                        // 기본 이미지
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
    DailyShuffleEntry(date: .now, games: WidgetGame.mockData, isPlaceholder: false)
}
