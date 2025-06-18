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

    /// Fetch realm status information for all realms in a region
    func realmStatus(region: String = "us") async throws -> RealmStatusResponse {
        print("BlizzardAPIService: Fetching live realm status for region: \(region)")
        
        // Use retail namespace since Classic realm status endpoints don't exist
        // We'll map retail server data to Classic servers in the UI layer
        let namespace = "dynamic-\(region)"
        
        return try await fetchRealmStatus(region: region, namespace: namespace)
    }
    
    /// Internal method to fetch realm status with specific namespace
    private func fetchRealmStatus(region: String, namespace: String) async throws -> RealmStatusResponse {
        let originalPath = "/data/wow/realm/index"
        
        guard var comps = URLComponents(string: "https://\(region).api.blizzard.com\(originalPath)") else {
            throw AppError.invalidURL(originalPath)
        }
        
        comps.queryItems = [
            URLQueryItem(name: "namespace", value: namespace),
            URLQueryItem(name: "locale", value: locale),
            URLQueryItem(name: "access_token", value: Secrets.oauthToken)
        ]
        
        guard let url = comps.url else { throw AppError.invalidURL(comps.string ?? "") }
        
        print("BlizzardAPIService: Trying realm status with namespace: \(namespace)")
        print("BlizzardAPIService: Requesting URL: \(url)")
        
        let (data, resp) = try await BlizzardAPIService.sharedSession.data(from: url)
        
        guard let http = resp as? HTTPURLResponse else {
            throw AppError.badStatus(code: 0)
        }
        
        print("BlizzardAPIService: Got status code \(http.statusCode) for namespace \(namespace)")
        
        guard (200...299).contains(http.statusCode) else {
            throw AppError.badStatus(code: http.statusCode)
        }
        
        do { 
            let result = try JSONDecoder().decode(RealmStatusResponse.self, from: data)
            print("BlizzardAPIService: Successfully decoded \(result.realms.count) realms")
            return result
        } catch { 
            print("BlizzardAPIService: Decoding error: \(error)")
            throw AppError.decodingFailure(entity: "RealmStatusResponse", underlying: error) 
        }
    }

    /// Fetch specific realm details
    func realm(slug: String) async throws -> RealmDetail {
        try await fetch(RealmDetail.self, endpoint: .init(path: "/data/wow/realm/\(slug)"))
    }

    /// Fetch connected realm status as fallback
    func connectedRealms(region: String = "us") async throws -> ConnectedRealmsResponse {
        let regionOverride = region
        let originalPath = "/data/wow/connected-realm/index"
        
        let namespaces = [
            "dynamic-classic1x-\(regionOverride)",
            "dynamic-classic-\(regionOverride)",
            "dynamic-\(regionOverride)"
        ]
        
        var lastError: Error?
        
        for namespace in namespaces {
            do {
                guard var comps = URLComponents(string: "https://\(regionOverride).api.blizzard.com\(originalPath)") else {
                    throw AppError.invalidURL(originalPath)
                }
                
                comps.queryItems = [
                    URLQueryItem(name: "namespace", value: namespace),
                    URLQueryItem(name: "locale", value: locale),
                    URLQueryItem(name: "access_token", value: Secrets.oauthToken)
                ]
                
                guard let url = comps.url else { throw AppError.invalidURL(comps.string ?? "") }
                
                print("BlizzardAPIService: Trying connected realms with namespace: \(namespace)")
                print("BlizzardAPIService: Requesting URL: \(url)")
                
                let (data, resp) = try await BlizzardAPIService.sharedSession.data(from: url)
                
                guard let http = resp as? HTTPURLResponse else {
                    throw AppError.badStatus(code: 0)
                }
                
                print("BlizzardAPIService: Got status code \(http.statusCode) for connected realms namespace \(namespace)")
                
                guard (200...299).contains(http.statusCode) else {
                    let statusCode = http.statusCode
                    lastError = AppError.badStatus(code: statusCode)
                    
                    if statusCode != 404 {
                        throw AppError.badStatus(code: statusCode)
                    }
                    continue
                }
                
                do { 
                    let result = try JSONDecoder().decode(ConnectedRealmsResponse.self, from: data)
                    print("BlizzardAPIService: Successfully decoded \(result.connected_realms.count) connected realms")
                    return result
                } catch {
                    print("BlizzardAPIService: Decoding error for connected realms: \(error)")
                    lastError = AppError.decodingFailure(entity: "ConnectedRealmsResponse", underlying: error)
                    continue
                }
                
            } catch {
                lastError = error
                if case AppError.badStatus(let code) = error, code == 404 {
                    continue
                } else {
                    throw error
                }
            }
        }
        
        throw lastError ?? AppError.badStatus(code: 404)
    }
    
    /// Fetch individual connected realm details
    func connectedRealm(id: Int, region: String = "us") async throws -> ConnectedRealmDetail {
        let namespaces = [
            "dynamic-classic1x-\(region)",
            "dynamic-classic-\(region)",
            "dynamic-\(region)"
        ]
        
        var lastError: Error?
        
        for namespace in namespaces {
            do {
                let originalPath = "/data/wow/connected-realm/\(id)"
                
                guard var comps = URLComponents(string: "https://\(region).api.blizzard.com\(originalPath)") else {
                    throw AppError.invalidURL(originalPath)
                }
                
                comps.queryItems = [
                    URLQueryItem(name: "namespace", value: namespace),
                    URLQueryItem(name: "locale", value: locale),
                    URLQueryItem(name: "access_token", value: Secrets.oauthToken)
                ]
                
                guard let url = comps.url else { throw AppError.invalidURL(comps.string ?? "") }
                
                let (data, resp) = try await BlizzardAPIService.sharedSession.data(from: url)
                
                guard let http = resp as? HTTPURLResponse,
                      (200...299).contains(http.statusCode) else {
                    let statusCode = (resp as? HTTPURLResponse)?.statusCode ?? 0
                    lastError = AppError.badStatus(code: statusCode)
                    
                    if statusCode != 404 {
                        throw AppError.badStatus(code: statusCode)
                    }
                    continue
                }
                
                do { 
                    return try JSONDecoder().decode(ConnectedRealmDetail.self, from: data)
                } catch {
                    lastError = AppError.decodingFailure(entity: "ConnectedRealmDetail", underlying: error)
                    continue
                }
                
            } catch {
                lastError = error
                if case AppError.badStatus(let code) = error, code == 404 {
                    continue
                } else {
                    throw error
                }
            }
        }
        
        throw lastError ?? AppError.badStatus(code: 404)
    }

    // Add further object wrappers as needed…
}

// MARK: - Realm Status Models

/// Response model for realm status index
struct RealmStatusResponse: Codable, Sendable {
    let realms: [RealmStatusInfo]
}

/// Individual realm status information
struct RealmStatusInfo: Codable, Sendable, Identifiable {
    let id: Int
    let name: String
    let slug: String
    let category: String
    let locale: String
    let timezone: String
    let type: RealmTypeInfo
    let is_tournament: Bool
    let region: RealmRegionInfo
    let connected_realm: ConnectedRealmInfo?
}

/// Realm type information
struct RealmTypeInfo: Codable, Sendable {
    let type: String
    let name: String
}

/// Realm region information  
struct RealmRegionInfo: Codable, Sendable {
    let name: String
    let id: Int
}

/// Connected realm information
struct ConnectedRealmInfo: Codable, Sendable {
    let href: String
}

/// Detailed realm information
struct RealmDetail: Codable, Sendable {
    let id: Int
    let name: String
    let slug: String
    let category: String
    let locale: String
    let timezone: String
    let type: RealmTypeInfo
    let is_tournament: Bool
    let region: RealmRegionInfo
    let connected_realm: ConnectedRealmInfo?
    let population: RealmPopulation?
}

/// Realm population information
struct RealmPopulation: Codable, Sendable {
    let type: String
    let name: String
}

/// Connected realms response model
struct ConnectedRealmsResponse: Codable, Sendable {
    let connected_realms: [ConnectedRealmRef]
}

/// Connected realm reference
struct ConnectedRealmRef: Codable, Sendable {
    let href: String
}

/// Connected realm detail model
struct ConnectedRealmDetail: Codable, Sendable {
    let id: Int
    let has_queue: Bool
    let status: ConnectedRealmStatus
    let population: ConnectedRealmPopulation
    let realms: [RealmInfo]
    let mythic_leaderboards: ConnectedRealmMythicLeaderboards?
    let auctions: ConnectedRealmAuctions?
}

/// Connected realm status
struct ConnectedRealmStatus: Codable, Sendable {
    let type: String
    let name: String
}

/// Connected realm population
struct ConnectedRealmPopulation: Codable, Sendable {
    let type: String
    let name: String
}

/// Individual realm info within connected realm
struct RealmInfo: Codable, Sendable {
    let id: Int
    let region: RealmRegionInfo
    let connected_realm: ConnectedRealmInfo
    let name: String
    let category: String
    let locale: String
    let timezone: String
    let type: RealmTypeInfo
    let is_tournament: Bool
    let slug: String
}

/// Connected realm mythic leaderboards
struct ConnectedRealmMythicLeaderboards: Codable, Sendable {
    let href: String
}

/// Connected realm auctions
struct ConnectedRealmAuctions: Codable, Sendable {
    let href: String
}
