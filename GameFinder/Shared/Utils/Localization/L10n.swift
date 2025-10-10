//
//  L10n.swift
//  GameFinder
//
//  Created by Suji Jang on 9/30/25.
//

import Foundation

enum L10n {
    
    static let edit = "edit".localized
    
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
        
        /// 게임 검색
        static let searchPlaceholder = "placeholder_search_games".localized
        
        /// 출시 예정
        static let upcomingGamesSectionHeader = "section_header_upcoming_games".localized
        
        /// 무료 게임
        static let freeGamesSectionHeader = "section_header_free_games".localized
        
        /// 인기 게임
        static let popularGamesSectionHeader = "section_header_popular_games".localized
    }
    
    enum Library {
        static let navTitle = "nav_title_second".localized
    }
    
    enum Settings {
        static let navTitle = "nav_title_third".localized
    }
    
    enum Alert {
        static let okButton = "alert_button_ok".localized
        
        static let languageTitle = "alert_title_language".localized
        static let languageMessage = "alert_message_language".localized
    }
}
