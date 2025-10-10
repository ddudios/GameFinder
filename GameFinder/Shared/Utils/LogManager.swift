//
//  LogManager.swift
//  GameFinder
//
//  Created by Claude on 10/11/25.
//

import Foundation
import OSLog
import FirebaseAnalytics

/// 앱 전체에서 사용할 로깅 매니저
final class LogManager {

    // MARK: - OSLog Categories

    /// 네트워크 관련 로그
    static let network = Logger(subsystem: Bundle.main.bundleIdentifier ?? "GameFinder", category: "Network")

    /// 데이터베이스 관련 로그
    static let database = Logger(subsystem: Bundle.main.bundleIdentifier ?? "GameFinder", category: "Database")

    /// 사용자 액션 관련 로그
    static let userAction = Logger(subsystem: Bundle.main.bundleIdentifier ?? "GameFinder", category: "UserAction")

    /// UI 관련 로그
    static let ui = Logger(subsystem: Bundle.main.bundleIdentifier ?? "GameFinder", category: "UI")

    /// 에러 관련 로그
    static let error = Logger(subsystem: Bundle.main.bundleIdentifier ?? "GameFinder", category: "Error")

    // MARK: - Firebase Analytics Wrapper

    /// Firebase Analytics 이벤트 전송
    /// - Parameters:
    ///   - name: 이벤트 이름
    ///   - parameters: 이벤트 파라미터
    static func logEvent(_ name: String, parameters: [String: Any]? = nil) {
        #if DEBUG
        network.debug("📊 Analytics Event: \(name), parameters: \(String(describing: parameters))")
        #endif
        Analytics.logEvent(name, parameters: parameters)
    }

    /// 화면 진입 이벤트 로깅
    /// - Parameter screenName: 화면 이름
    static func logScreenView(_ screenName: String, screenClass: String? = nil) {
        let parameters: [String: Any] = [
            AnalyticsParameterScreenName: screenName,
            AnalyticsParameterScreenClass: screenClass ?? screenName
        ]
        logEvent(AnalyticsEventScreenView, parameters: parameters)
        ui.info("🖥️ Screen View: \(screenName)")
    }

    /// 게임 조회 이벤트 로깅
    /// - Parameters:
    ///   - gameId: 게임 ID
    ///   - gameName: 게임 이름
    static func logGameView(gameId: Int, gameName: String) {
        let parameters: [String: Any] = [
            "game_id": gameId,
            "game_name": gameName
        ]
        logEvent("game_view", parameters: parameters)
    }

    /// 검색 이벤트 로깅
    /// - Parameter query: 검색어
    static func logSearch(query: String) {
        let parameters: [String: Any] = [
            AnalyticsParameterSearchTerm: query
        ]
        logEvent(AnalyticsEventSearch, parameters: parameters)
        userAction.info("🔍 Search: \(query)")
    }

    /// API 에러 로깅
    /// - Parameters:
    ///   - endpoint: API 엔드포인트
    ///   - errorMessage: 에러 메시지
    static func logAPIError(endpoint: String, errorMessage: String) {
        let parameters: [String: Any] = [
            "endpoint": endpoint,
            "error_message": errorMessage
        ]
        logEvent("api_error", parameters: parameters)
        error.error("❌ API Error: \(endpoint) - \(errorMessage)")
    }

    // MARK: - Favorites

    static func logAddFavorite(gameId: Int, gameName: String) {
        let parameters: [String: Any] = [
            "game_id": gameId,
            "game_name": gameName
        ]
        logEvent("add_favorite", parameters: parameters)
        userAction.info("❤️ Add Favorite: \(gameName) (id: \(gameId))")
    }

    static func logRemoveFavorite(gameId: Int) {
        let parameters: [String: Any] = [
            "game_id": gameId
        ]
        logEvent("remove_favorite", parameters: parameters)
        userAction.info("💔 Remove Favorite: (id: \(gameId))")
    }

    // MARK: - Notifications

    static func logAddNotification(gameId: Int, gameName: String) {
        let parameters: [String: Any] = [
            "game_id": gameId,
            "game_name": gameName
        ]
        logEvent("add_notification", parameters: parameters)
        userAction.info("🔔 Add Notification: \(gameName) (id: \(gameId))")
    }

    static func logRemoveNotification(gameId: Int) {
        let parameters: [String: Any] = [
            "game_id": gameId
        ]
        logEvent("remove_notification", parameters: parameters)
        userAction.info("🔕 Remove Notification: (id: \(gameId))")
    }

    // MARK: - Reading (Diary)

    static func logAddReading(gameId: Int, gameName: String) {
        let parameters: [String: Any] = [
            "game_id": gameId,
            "game_name": gameName
        ]
        logEvent("add_reading", parameters: parameters)
        userAction.info("📖 Add Reading: \(gameName) (id: \(gameId))")
    }

    static func logRemoveReading(gameId: Int) {
        let parameters: [String: Any] = [
            "game_id": gameId
        ]
        logEvent("remove_reading", parameters: parameters)
        userAction.info("📕 Remove Reading: (id: \(gameId))")
    }

    // MARK: - Diary

    static func logCreateDiary(gameId: Int, gameName: String, mediaCount: Int) {
        let parameters: [String: Any] = [
            "game_id": gameId,
            "game_name": gameName,
            "media_count": mediaCount
        ]
        logEvent("create_diary", parameters: parameters)
        userAction.info("✍️ Create Diary: \(gameName) (id: \(gameId)), media: \(mediaCount)")
    }

    static func logUpdateDiary(gameId: Int, mediaCount: Int) {
        let parameters: [String: Any] = [
            "game_id": gameId,
            "media_count": mediaCount
        ]
        logEvent("update_diary", parameters: parameters)
        userAction.info("✏️ Update Diary: (id: \(gameId)), media: \(mediaCount)")
    }

    static func logDeleteDiary(gameId: Int) {
        let parameters: [String: Any] = [
            "game_id": gameId
        ]
        logEvent("delete_diary", parameters: parameters)
        userAction.info("🗑️ Delete Diary: (id: \(gameId))")
    }
}
