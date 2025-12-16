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
    let coverImagePath: String?
    let platform: String
    let genre: String
    let releaseDate: Date

    static var mockData: [WidgetGame] {
        [
            WidgetGame(id: 1, title: "Ethereal Shards", coverImagePath: "EtherealShards", platform: "PlayStation", genre: "Action, RPG", releaseDate: Date())
//            WidgetGame(id: 1, title: "Ethereal Shardsdasdfsasdfasd", coverImagePath: "EtherealShards", platform: "PlayStasdjlfalskdf;dafsdfasdfasfasdflasdkjfa;klsjdfdafsdfasdfasdfaasdfasdftion", genre: "Actdafsdfaasdfsdfasdfsdfion, RPG", releaseDate: Date())
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
        let entry = DailyShuffleEntry(
            date: Date(),
            games: WidgetGame.mockData,
            isPlaceholder: false
        )

        let nextUpdate = Calendar.current.startOfDay(for: Date())
            .addingTimeInterval(60 * 60 * 24)

        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

//    func relevances() async -> WidgetRelevances<ConfigurationAppIntent> {
//        // Generate a list containing the contexts this widget is relevant in.
//    }
}

struct GameFinderWidgetEntryView : View {
    var entry: DailyShuffleEntry

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Game Finder")
                    .font(.headline)
                Divider()
                ForEach(entry.games) { game in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(game.title)
                            .font(.body)
                            .lineLimit(1)
                        Text(game.releaseDate, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        Text(game.platform)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                        Text(game.genre)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .padding(.leading, 24)
            
            if let game = entry.games.first,
               let imagePath = game.coverImagePath {
                Image(imagePath)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 140)
                    .clipped()
            }
        }
        .padding(.vertical, 24)
        .redacted(reason: entry.isPlaceholder ? .placeholder : [])
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
        .description("새롭게 출시되는 게임을 빠르게 확인할 수 있습니다.")
        .supportedFamilies([.systemMedium])
    }
}

#Preview(as: .systemMedium) {
    GameFinderWidget()
} timeline: {
    DailyShuffleEntry(date: .now, games: WidgetGame.mockData, isPlaceholder: false)
}
