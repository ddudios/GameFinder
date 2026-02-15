//
//  L10n.swift
//  GameFinder
//
//  Created by Suji Jang on 9/30/25.
//

import Foundation

enum L10n {
    
    static let edit = "edit".localized
    static let save = "save".localized
    static let cancel = "cancel".localized
    static let delete = "delete".localized
    static let error = "error".localized
    
    static let today = "today".localized
    static let tomorrow = "tomorrow".localized
    
    static let diary = "diary".localized
    static let favorite = "favorite".localized
    static let notification = "notification".localized
    
    enum TabBar {
        /// Finder
        static let first = "tab_bar_title_first".localized

        /// Library
        static let second = "tab_bar_title_second".localized

        /// Settings
        static let third = "tab_bar_title_third".localized

        /// Calendar
        static let fourth = "tab_bar_title_fourth".localized
    }
    
    enum Error {
        static let invalidURL = "error_invalidURL_message".localized
        static let invalidResponse = "error_invalidResponse_message".localized
        static let noData = "error_noData_message".localized
        static let decodingFailed = "error_decodingFailed_message".localized
        static let apiLimitExceeded = "error_apiLimitExceeded_message".localized
        static let notFound = "error_notFound_message".localized
        static let server = "error_server_message".localized
        static let unknown = "error_unknown_message".localized
    }
    
    enum Finder {
        /// Game Finder
        static let navTitle = "nav_title_first".localized
        
        /// 출시 예정
        static let upcomingGamesSectionHeader = "section_header_upcoming_games".localized
        
        /// 무료 게임
        static let freeGamesSectionHeader = "section_header_free_games".localized
        
        /// 인기 게임
        static let popularGamesSectionHeader = "section_header_popular_games".localized
    }
    
    enum GameDetail {
        static let diaryDeleteAlertTitle = "game_detail_alert_title_diary_delete".localized
        
        static let noData = "game_detail_no_data".localized
        
        static let genre = "game_detail_section_genre".localized
        static let ageRating = "game_detail_section_age_rating".localized
        static let platform = "game_detail_section_platform".localized
        static let description = "game_detail_section_description".localized
        static let developer = "game_detail_section_developer".localized
        static let publisher = "game_detail_section_publisher".localized
    }
    
    enum Search {
        /// 검색
        static let navTitle = "nav_title_search".localized
        static let resultNavTitle = "nav_title_search_results".localized
        
        /// 게임 검색
        static let searchPlaceholder = "placeholder_search_games".localized
        static let emptyResultMessage = "search_result_empty_message"

        static let filterAll = "search_filter_all".localized
        static let filterWindows = "search_filter_windows".localized
        static let filterMacOS = "search_filter_macos".localized
        static let filterLinux = "search_filter_linux".localized
        static let filterXbox = "search_filter_xbox".localized
        static let filterPlayStation = "search_filter_playstation".localized
        static let filterNintendo = "search_filter_nintendo".localized
        static let filterIOS = "search_filter_ios".localized
        static let filterAndroid = "search_filter_android".localized
    }
    
    enum Library {
        static let navTitle = "nav_title_second".localized
        static let emptyLable = "label_placeholder_empty".localized
    }
    
    enum Diary {
        static let emptyLabel = "diary_empty_label".localized
        
        static let deleteAlertTitle = "diary_alert_title_delete".localized
        static let deleteLogAlertMessage = "diary_alert_message_delete_log".localized
        
        static let deleteFailedToast = "diary_toast_delete_failed".localized
        
        static let saveFailedAlertTitle = "diary_alert_title_save_fail".localized
        static let saveFailedAlertMessage = "diary_alert_message_save_fail".localized
        
        static let titlePlaceholder = "diary_placeholder_title".localized
        static let contentPlaceholder = "diary_placeholder_content".localized
    }
    
    enum Settings {
        static let navTitle = "nav_title_third".localized
        
        // Section
        static let general = "setting_section_general".localized
        static let support = "setting_section_support".localized
        
        // Cell
        static let language = "setting_cell_language".localized
        static let contact = "setting_cell_contact".localized
        
        // Alert
        static let notiMessage = "setting_noti_message".localized
        static let notiOn = "setting_noti_on".localized
        static let notiOff = "setting_noti_off".localized
        static let notiEnabled = "setting_noti_enabled".localized
        static let notiDisabled = "setting_noti_disabled".localized
        
        static let appNotiTitle = "setting_app_noti_title".localized
        static let appNotiMessage = "setting_app_noti_message".localized
        static let appNotiSettingButton = "setting_app_noti_button".localized
        
        static let contactMessage = "setting_contact_message".localized

        // Email
        static let emailSent = "setting_email_sent".localized
        static let emailSaved = "setting_email_saved".localized
        static let emailCancelled = "setting_email_cancelled".localized
        static let emailFailed = "setting_email_failed".localized

        // Sheet
        static let languageSheetTitle = "setting_language_sheet_title".localized
        static let languageSheetMessage = "setting_language_sheet_message".localized
    }
    
    enum Alert {
        static let okButton = "alert_button_ok".localized

        static let languageTitle = "alert_title_language".localized
        static let languageMessage = "alert_message_language".localized
    }

    enum Notification {
        static let title = "notification_title".localized
        static let body = "notification_body".localized
        static let added = "notification_added".localized
        static let removed = "notification_removed".localized
        static let turnOnTitle = "notification_turn_on_title".localized
        static let turnOnMessage = "notification_turn_on_message".localized
        static let turnOnButton = "notification_turn_on_button".localized
        static let discountComingSoon = "notification_discount_coming_soon".localized
    }

    enum Calendar {
        static let emptyMessage = "calendar_empty_message".localized
    }
}
