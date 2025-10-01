//
//  Game.swift
//  GameFinder
//
//  Created by Suji Jang on 10/1/25.
//

import Foundation

struct Game {
    let id: Int
    let title: String
    let description: String
    let metacritic: Int?
    let releaseDate: Date?
    let website: URL?
    let rating: Double
    let ratingTop: Int
    let added: Int
    let playtime: Int
    let platforms: [String]    // 플랫폼 이름만 추출
    let stores: [String]       // 스토어 이름만 추출
    let developers: [String]
    let genres: [String]
    let tags: [String]
    let esrb: String?
    let backgroundImageURL: String?
}
