//
//  AppIntent.swift
//  GameFinderWidget
//
//  Created by Suji Jang on 12/12/25.
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "출시 예정 게임 추천" }
    static var description: IntentDescription { "매일 새로운 게임을 추천받습니다." }

    @Parameter(title: "Get another game recommendation", default: "🎮")
    var shuffle: String
    func perform() async throws -> some IntentResult {
        return .result()
    }
}
