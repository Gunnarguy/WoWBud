//
//  ClassicAPIService.swift
//  WoWBud
//
//  Created on 4/30/25.
//

import Foundation
import os

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
    // Namespace for Classic Era Anniversary Edition (1.15.x) - now with region
    nonisolated private let classic1xNamespace = "static-classic1x-us"
    // Fallback namespaces for older data sets - now with region
    nonisolated private let classicEraNamespace = "static-classic-era-us"
    nonisolated private let classicNamespace = "static-classic-us"
    // nonisolated private let retailNamespace = "static-us"

    // MARK: - OAuth Token Management
    private var tokenResponse: TokenResponse?

    // Fetch Client ID and Secret from Secrets.swift (ensure these exist)
    nonisolated private let clientID = Secrets.clientID
    nonisolated private let clientSecret = Secrets.clientSecret

    // MARK: - Cached session
    nonisolated private static let sharedSession: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.httpAdditionalHeaders = ["Accept-Encoding": "gzip"]
        cfg.urlCache = .shared
        return URLSession(configuration: cfg)
    }()

    // MARK: - Generic fetch
    /// Generic function to fetch and decode data from a Blizzard API endpoint.
    /// Automatically handles fetching/refreshing the OAuth token.
    /// - Parameters:
    ///   - type: The `Decodable` type to decode the response into.
    ///   - endpoint: The `Endpoint` struct containing path and parameters.
    ///   - namespaceOverride: Optional namespace to use instead of the default classic1x one.
    /// - Returns: The decoded object of type `T`.
    /// - Throws: `AppError` for network, status code, decoding, or OAuth issues.
    func fetch<T: Decodable & Sendable>(
        _ type: T.Type,
        endpoint: Endpoint,
        namespaceOverride: String? = nil,
        retryOnAuthError: Bool = true
    ) async throws -> T {
        // --- Get a valid OAuth token ---
        let token = try await getValidAccessToken()

        // --- Construct URL ---
        guard
            var comps = URLComponents(string: "https://\(region).api.blizzard.com\(endpoint.path)")
        else {
            throw AppError.invalidURL(endpoint.path)
        }

        // Use the override namespace if provided, otherwise default to classic1xNamespace
        let effectiveNamespace = namespaceOverride ?? classic1xNamespace

        comps.queryItems =
            endpoint.params + [
                // Use the determined namespace
                URLQueryItem(name: "namespace", value: effectiveNamespace),
                URLQueryItem(name: "locale", value: locale),
            ]

        guard let url = comps.url else { throw AppError.invalidURL(comps.string ?? "") }

        // --- Create Request with Auth Header ---
        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")  // Add token to header
        // No need to add namespace header here, it's in the query params

        // --- Perform the network request ---
        let (data, resp) = try await ClassicAPIService.sharedSession.data(for: request)  // Use the prepared request

        // Check for successful HTTP status code
        guard let http = resp as? HTTPURLResponse,
            (200...299).contains(http.statusCode)
        else {
            let statusCode = (resp as? HTTPURLResponse)?.statusCode ?? 0
            if (statusCode == 401 || statusCode == 403) && retryOnAuthError {
                print("Auth Error (\(statusCode)) - Token might be invalid. Invalidating and retrying...")
                self.tokenResponse = nil
                return try await fetch(type, endpoint: endpoint, namespaceOverride: namespaceOverride, retryOnAuthError: false)
            }
            throw AppError.badStatus(code: statusCode)
        }

        // Decode the JSON response
        do {
            let decoder = JSONDecoder()
            // RE-ENABLED: Snake case conversion strategy to handle API's naming convention
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(T.self, from: data)
        } catch {
            // Throw specific error for decoding failures
            print("Decoding Error for \(T.self): \(error)")  // Log detailed decoding error
            print("Raw Data: \(String(data: data, encoding: .utf8) ?? "Unable to decode data")")  // Log raw data
            throw AppError.decodingFailure(entity: "\(T.self)", underlying: error)
        }
    }

    // MARK: - API Endpoints

    // Spell Endpoint
    func spell(id: Int) async throws -> Spell {
        // Ensure this uses the generic fetch which now handles namespace and auth
        try await fetch(Spell.self, endpoint: .init(path: "/data/wow/spell/\(id)"))
    }

    /// Search for items by name
    /// - Parameter name: The name or partial name to search for
    /// - Returns: An `ItemSearchResponse` containing search results
    func searchItems(name: String) async throws -> ItemSearchResponse {
        let searchEndpoint = Endpoint(
            path: "/data/wow/search/item",
            params: [
                URLQueryItem(name: "name.en_US", value: name),
                URLQueryItem(name: "_page", value: "1"),
                URLQueryItem(name: "_pageSize", value: "50")
            ]
        )
        return try await fetch(ItemSearchResponse.self, endpoint: searchEndpoint)
    }

    /// Fetches item media by ID (alias for the existing media method)
    /// - Parameter id: The ID of the item
    /// - Returns: A `Media` object containing asset information
    func fetchItemMedia(id: Int) async throws -> Media {
        return try await media(id: id)
    }

    // Item Endpoint - Simplified for Classic 1.x
    /// Fetches item details by ID using the `static-classic1x` namespace.
    /// - Parameter id: The ID of the item.
    /// - Returns: An `Item` object.
    /// - Throws: `AppError` if the item is not found or other errors occur.
    func item(id: Int) async throws -> Item {
        let itemEndpoint = Endpoint(path: "/data/wow/item/\(id)")

        // Try the Anniversary/Fresh namespace first
        do {
            print("ClassicAPIService: Requesting item \(id) in \(classic1xNamespace)")
            return try await fetch(Item.self, endpoint: itemEndpoint, namespaceOverride: classic1xNamespace)
        } catch AppError.badStatus(code: 404) {
            print("Item \(id) not found in \(classic1xNamespace). Trying classic-era namespace…")
        } catch {
            print("Error fetching item \(id) from \(classic1xNamespace): \(error)")
            // Do not rethrow; allow fallback to continue
        }

        // Fallback: try classic-era namespace
        do {
            print("ClassicAPIService: Requesting item \(id) in \(classicEraNamespace)")
            return try await fetch(
                Item.self,
                endpoint: itemEndpoint,
                namespaceOverride: classicEraNamespace
            )
        } catch AppError.badStatus(code: 404) {
            print("Item \(id) not found in \(classicEraNamespace). Trying classic namespace…")
        } catch {
            print("Error fetching item \(id) from \(classicEraNamespace): \(error)")
            // Do not rethrow; allow fallback to continue
        }

        // Final fallback: classic namespace
        do {
            print("ClassicAPIService: Requesting item \(id) in \(classicNamespace)")
            return try await fetch(
                Item.self,
                endpoint: itemEndpoint,
                namespaceOverride: classicNamespace
            )
        } catch {
            print("API Error loading item \(id): \(error)")
            throw error
        }
    }

    /// Fetches media details (like an item's icon) by its ID.
    /// It tries the primary classic namespace first, then falls back to the era-specific one.
    /// - Parameter id: The ID of the media to fetch.
    /// - Returns: A `Media` object containing asset information.
    func media(id: Int) async throws -> Media {
        let mediaEndpoint = Endpoint(path: "/data/wow/media/item/\(id)")

        // Try the primary classic namespace first
        do {
            return try await fetch(Media.self, endpoint: mediaEndpoint, namespaceOverride: classic1xNamespace)
        } catch AppError.badStatus(code: 404) {
            print("Media for item \(id) not found in \(classic1xNamespace). Trying classic-era…")
            // Fall through to the next try block
        } catch {
            // For other errors, we might want to log them but still try the fallback
            print("An error occurred fetching media in \(classic1xNamespace): \(error)")
        }

        // Fallback to the classic-era namespace
        do {
            return try await fetch(Media.self, endpoint: mediaEndpoint, namespaceOverride: classicEraNamespace)
        } catch {
            print("Failed to fetch media from \(classicEraNamespace) as well: \(error)")
            throw error // Rethrow the error from the last attempt
        }
    }

    // MARK: - OAuth Token Management

    /// Ensures a valid OAuth token is available, fetching a new one if needed.
    /// This function is the single source of truth for getting a valid token.
    /// - Returns: A valid OAuth access token string.
    private func getValidAccessToken() async throws -> String {
        if let existingToken = tokenResponse, !existingToken.isExpired {
            return existingToken.accessToken
        }

        print("Fetching new OAuth token...")
        let newTokenResponse = try await OAuth.fetchToken(clientID: clientID, clientSecret: clientSecret)
        self.tokenResponse = newTokenResponse
        print("Successfully fetched new OAuth token.")
        return newTokenResponse.accessToken
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

/// Response structure for item classes index
struct ItemClassesIndex: Codable, Sendable {
    let itemClasses: [ItemClassReference]

    struct ItemClassReference: Codable, Identifiable, Sendable {
        let id: Int
        let name: String
    }
}

// MARK: - Detail Responses

/// Response structure for a specific item class
struct ItemClassDetail: Codable, Identifiable, Sendable {
    let id: Int
    let name: String
    let itemSubclasses: [ItemSubclassReference]

    struct ItemSubclassReference: Codable, Identifiable, Sendable {
        let id: Int
        let name: String
    }
}

/// Response structure for a specific item subclass
struct ItemSubclassDetail: Codable, Identifiable, Sendable {
    let id: Int
    let name: String
    let verboseName: String?  // Optional verbose name
    // Add other fields if needed from the API response, like inventory_types
}

// MARK: - Search Response Structures

/// Represents a single item returned in a search result from the API.
struct ItemSearchResult: Codable, Sendable {
    // The actual item data is nested inside the 'data' property.
    let data: Item
}

/// Represents the overall response from an item search query.
struct ItemSearchResponse: Codable, Sendable {
    let page: Int
    let pageSize: Int
    let maxPageSize: Int
    let pageCount: Int
    let results: [ItemSearchResult]  // Array of search result items
}
