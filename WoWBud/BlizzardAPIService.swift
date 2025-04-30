//
//  BlizzardAPIService.swift
//  WoWClassicBuilder
//
//  Swift 6 – actor-isolated, Sendable safe
//

import Foundation

/// Thread-safe async façade for Blizzard “static-classic-XX” namespace.
/// All mutable state isolated to the actor.
actor BlizzardAPIService {

    // MARK: - Endpoint helper
    struct Endpoint: Sendable {
        var path: String
        var params: [URLQueryItem] = []
    }

    // MARK: - Constants (non-isolated, pure)
    nonisolated private let region  = "us"
    nonisolated private let locale  = "en_US"

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
            URLQueryItem(name: "namespace",    value: "static-classic-\(region)"),
            URLQueryItem(name: "locale",       value: locale),
            URLQueryItem(name: "access_token", value: Secrets.oauthToken)
        ]

        guard let url = comps.url else { throw AppError.invalidURL(comps.string ?? "") }

        let (data, resp) = try await BlizzardAPIService.sharedSession.data(from: url)

        guard let http = resp as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            throw AppError.badStatus(code: (resp as? HTTPURLResponse)?.statusCode ?? 0)
        }

        do { return try JSONDecoder().decode(T.self, from: data) }
        catch { throw AppError.decodingFailure(entity: "\(T.self)", underlying: error) }
    }

    // Convenience wrappers ---------------------------------------------------

    func spell(id: Int) async throws -> Spell {
        try await fetch(Spell.self, endpoint: .init(path: "/data/wow/spell/\(id)"))
    }

    func item(id: Int) async throws -> Item {
        try await fetch(Item.self, endpoint: .init(path: "/data/wow/item/\(id)"))
    }

    // Add further object wrappers as needed…
}
