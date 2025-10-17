//
//  L10n.swift
//  GameFinder
//
//  Created by Suji Jang on 9/30/25.
//

import Foundation

enum L10n {
    
    static let edit = "edit".localized
    
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
    
    enum Search {
        /// 검색
        static let navTitle = "nav_title_search".localized
        static let resultNavTitle = "nav_title_search_results".localized
        
        /// 게임 검색
        static let searchPlaceholder = "placeholder_search_games".localized
    }
    
    enum Library {
        static let navTitle = "nav_title_second".localized
        static let emptyLable = "label_placeholder_empty".localized
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
        
        // Sheet
        static let languageSheetTitle = "setting_language_sheet_title".localized
        static let languageSheetMessage = "setting_language_sheet_message".localized
    }
    
    enum Alert {
        static let okButton = "alert_button_ok".localized
        static let cancelButton = "alert_button_cancel".localized

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
    }
}
