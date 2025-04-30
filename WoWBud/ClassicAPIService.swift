//
//  ClassicAPIService.swift
//  WoWBud
//
//  Created on 4/30/25.
//

import Foundation

/// Thread-safe async façade for Blizzard "classic-era" namespace.
/// All mutable state isolated to the actor.
actor ClassicAPIService {

    // MARK: - Endpoint helper
    struct Endpoint: Sendable {
        var path: String
        var params: [URLQueryItem] = []
    }

    // MARK: - Constants (non-isolated, pure)
    nonisolated private let region = "us"
    nonisolated private let locale = "en_US"
    nonisolated private let namespace = "static-classic-era"

    // MARK: - Cached session
    nonisolated private static let sharedSession: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.httpAdditionalHeaders = ["Accept-Encoding": "gzip"]
        cfg.urlCache = .shared
        return URLSession(configuration: cfg)
    }()

    // MARK: - Generic fetch
    func fetch<T: Decodable & Sendable>(_ type: T.Type,
                                        endpoint: Endpoint) async throws -> T {
        guard var comps = URLComponents(string: "https://\(region).api.blizzard.com\(endpoint.path)") else {
            throw AppError.invalidURL(endpoint.path)
        }

        comps.queryItems = endpoint.params + [
            URLQueryItem(name: "namespace", value: "\(namespace)-\(region)"),
            URLQueryItem(name: "locale", value: locale),
            URLQueryItem(name: "access_token", value: Secrets.oauthToken)
        ]

        guard let url = comps.url else { throw AppError.invalidURL(comps.string ?? "") }

        let (data, resp) = try await ClassicAPIService.sharedSession.data(from: url)

        guard let http = resp as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            throw AppError.badStatus(code: (resp as? HTTPURLResponse)?.statusCode ?? 0)
        }

        do { return try JSONDecoder().decode(T.self, from: data) }
        catch { throw AppError.decodingFailure(entity: "\(T.self)", underlying: error) }
    }

    // MARK: - API Endpoints
    
    // Spell Endpoint
    func spell(id: Int) async throws -> Spell {
        try await fetch(Spell.self, endpoint: .init(path: "/data/wow/spell/\(id)"))
    }
    
    // Item Endpoint
    func item(id: Int) async throws -> Item {
        try await fetch(Item.self, endpoint: .init(path: "/data/wow/item/\(id)"))
    }
    
    // Class Endpoint
    func playableClass(id: Int) async throws -> PlayableClass {
        try await fetch(PlayableClass.self, endpoint: .init(path: "/data/wow/playable-class/\(id)"))
    }
    
    // Classes Index
    func playableClasses() async throws -> PlayableClassesIndex {
        try await fetch(PlayableClassesIndex.self, endpoint: .init(path: "/data/wow/playable-class/index"))
    }
    
    // Race Endpoint
    func playableRace(id: Int) async throws -> PlayableRace {
        try await fetch(PlayableRace.self, endpoint: .init(path: "/data/wow/playable-race/\(id)"))
    }
    
    // Races Index
    func playableRaces() async throws -> PlayableRacesIndex {
        try await fetch(PlayableRacesIndex.self, endpoint: .init(path: "/data/wow/playable-race/index"))
    }
    
    // Talent tree
    func talentTree(classID: Int) async throws -> TalentTree {
        // This is a mock endpoint since talent trees work differently in Classic
        // In a real app, this would fetch from a different source or use a proper endpoint
        try await fetch(TalentTree.self, endpoint: .init(path: "/data/wow/talent-tree/\(classID)"))
    }
}

// MARK: - Index Responses

/// Response structure for playable classes index
struct PlayableClassesIndex: Codable, Sendable {
    let classes: [ClassReference]
    
    struct ClassReference: Codable, Identifiable, Sendable {
        let id: Int
        let name: String
    }
}

/// Response structure for playable races index
struct PlayableRacesIndex: Codable, Sendable {
    let races: [RaceReference]
    
    struct RaceReference: Codable, Identifiable, Sendable {
        let id: Int
        let name: String
    }
}
