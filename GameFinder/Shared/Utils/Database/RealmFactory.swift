//
//  RealmFactory.swift
//  GameFinder
//
//  Created by Codex on 2/18/26.
//

import Foundation
import RealmSwift

enum RealmFactory {
    static func mainRealm() throws -> Realm {
        try Realm()
    }

    static func finderCacheRealm() throws -> Realm {
        let defaultURL = Realm.Configuration.defaultConfiguration.fileURL
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("default.realm")

        let cacheURL = defaultURL.deletingLastPathComponent()
            .appendingPathComponent("finder-cache.realm")

        let configuration = Realm.Configuration(
            fileURL: cacheURL,
            schemaVersion: 2,
            deleteRealmIfMigrationNeeded: true,
            objectTypes: [
                RealmFinderSectionCacheMeta.self,
                RealmFinderSectionItem.self
            ]
        )

        return try Realm(configuration: configuration)
    }
}
