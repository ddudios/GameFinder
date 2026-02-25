//
//  RealmFinderCacheRepository.swift
//  GameFinder
//
//  Created by Codex on 2/18/26.
//

import Foundation
import RealmSwift

final class RealmFinderCacheRepository: FinderCacheRepository {

    func load(section: FinderCacheSection) -> [Game] {
        guard let realm = try? RealmFactory.finderCacheRealm() else {
            LogManager.database.error("Failed to open finder cache realm for section: \(section.rawValue)")
            return []
        }

        let items = realm.objects(RealmFinderSectionItem.self)
            .where { $0.sectionKey == section.rawValue }
            .sorted(byKeyPath: "sortOrder", ascending: true)

        return Array(items.map { item in
            Game(
                id: item.gameId,
                name: item.name,
                released: item.released,
                backgroundImage: item.backgroundImage,
                rating: item.rating,
                ratingsCount: item.ratingsCount,
                metacritic: item.metacritic,
                platforms: [],
                genres: self.decodeGenres(from: item.genresJSON),
                screenshots: [],
                readingUpdatedAt: nil
            )
        })
    }

    func save(section: FinderCacheSection, games: [Game], fetchedAt: Date) {
        guard let realm = try? RealmFactory.finderCacheRealm() else {
            LogManager.database.error("Failed to open finder cache realm for save: \(section.rawValue)")
            return
        }

        let limitedGames = Array(games.prefix(section.maxItemCount))
        let sectionKey = section.rawValue

        do {
            try realm.write {
                let oldItems = realm.objects(RealmFinderSectionItem.self)
                    .where { $0.sectionKey == sectionKey }
                realm.delete(oldItems)

                for (index, game) in limitedGames.enumerated() {
                    let item = RealmFinderSectionItem()
                    item.id = "\(sectionKey)_\(game.id)"
                    item.sectionKey = sectionKey
                    item.sortOrder = index
                    item.gameId = game.id
                    item.name = game.name
                    item.released = game.released
                    item.backgroundImage = game.backgroundImage
                    item.rating = game.rating
                    item.ratingsCount = game.ratingsCount
                    item.metacritic = game.metacritic
                    item.genresJSON = encodeGenres(game.genres)
                    realm.add(item, update: .modified)
                }

                if let existingMeta = realm.object(
                    ofType: RealmFinderSectionCacheMeta.self,
                    forPrimaryKey: sectionKey
                ) {
                    existingMeta.fetchedAt = fetchedAt
                    existingMeta.ttlSeconds = Int(section.ttl)
                } else {
                    let meta = RealmFinderSectionCacheMeta()
                    meta.sectionKey = sectionKey
                    meta.fetchedAt = fetchedAt
                    meta.ttlSeconds = Int(section.ttl)
                    realm.add(meta)
                }
            }

            LogManager.database.debug("Saved finder cache section: \(section.rawValue), count: \(limitedGames.count)")
        } catch {
            LogManager.database.error("Failed to save finder cache section: \(section.rawValue), error: \(error.localizedDescription)")
        }
    }

    func isFresh(section: FinderCacheSection, now: Date) -> Bool {
        guard let realm = try? RealmFactory.finderCacheRealm() else {
            return false
        }

        guard let meta = realm.object(
            ofType: RealmFinderSectionCacheMeta.self,
            forPrimaryKey: section.rawValue
        ) else {
            return false
        }

        let age = now.timeIntervalSince(meta.fetchedAt)
        return age < TimeInterval(meta.ttlSeconds)
    }

    func clear(section: FinderCacheSection) {
        guard let realm = try? RealmFactory.finderCacheRealm() else { return }

        do {
            try realm.write {
                let sectionKey = section.rawValue
                let items = realm.objects(RealmFinderSectionItem.self)
                    .where { $0.sectionKey == sectionKey }
                realm.delete(items)

                if let meta = realm.object(ofType: RealmFinderSectionCacheMeta.self, forPrimaryKey: sectionKey) {
                    realm.delete(meta)
                }
            }
        } catch {
            LogManager.database.error("Failed to clear finder cache section: \(section.rawValue), error: \(error.localizedDescription)")
        }
    }

    private func encodeGenres(_ genres: [GameGenre]) -> String {
        let names = genres.map(\.name)
        guard let data = try? JSONEncoder().encode(names),
              let json = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return json
    }

    private func decodeGenres(from json: String) -> [GameGenre] {
        guard let data = json.data(using: .utf8),
              let names = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }

        return names.enumerated().map { index, name in
            let slug = name.lowercased().replacingOccurrences(of: " ", with: "-")
            return GameGenre(id: index, name: name, slug: slug)
        }
    }
}
