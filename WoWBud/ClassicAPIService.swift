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
    // Namespace for Classic Era Anniversary Edition (1.15.x)
    nonisolated private let classic1xNamespace = "static-classic1x"
    // Fallback namespaces for older data sets
    nonisolated private let classicEraNamespace = "static-classic-era"
    nonisolated private let classicNamespace = "static-classic"
    // nonisolated private let retailNamespace = "static-us"

    // MARK: - OAuth Token Management
    private var currentAccessToken: String?
    private var tokenExpirationTime: Date?

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
        namespaceOverride: String? = nil
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
        let effectiveNamespace = namespaceOverride ?? classic1xNamespace  // Use corrected default

        comps.queryItems =
            endpoint.params + [
                // Use the determined namespace
                URLQueryItem(name: "namespace", value: "\(effectiveNamespace)-\(region)"),  // Construct full namespace
                URLQueryItem(name: "locale", value: locale),
                // REMOVED: Token is now added via header below
                // URLQueryItem(name: "access_token", value: Secrets.oauthToken),
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
            // Throw specific error for bad status codes
            let statusCode = (resp as? HTTPURLResponse)?.statusCode ?? 0
            // If 401/403, potentially invalidate token? For now, just throw.
            if statusCode == 401 || statusCode == 403 {
                print("Auth Error (\(statusCode)) - Token might be invalid.")
                // Invalidate local token copy to force refetch next time
                currentAccessToken = nil
                tokenExpirationTime = nil
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
            return try await fetch(Item.self, endpoint: itemEndpoint)
        } catch AppError.badStatus(code: 404) {
            print("Item \(id) not found in \(classic1xNamespace). Trying classic-era namespace…")
        } catch {
            print("Error fetching item \(id) from \(classic1xNamespace): \(error)")
            throw error
        }

        // Fallback: try classic-era namespace
        do {
            return try await fetch(
                Item.self,
                endpoint: itemEndpoint,
                namespaceOverride: classicEraNamespace
            )
        } catch AppError.badStatus(code: 404) {
            print("Item \(id) not found in \(classicEraNamespace). Trying classic namespace…")
        } catch {
            print("Error fetching item \(id) from \(classicEraNamespace): \(error)")
            throw error
        }

        // Final fallback: classic namespace
        do {
            return try await fetch(
                Item.self,
                endpoint: itemEndpoint,
                namespaceOverride: classicNamespace
            )
        } catch {
            print("Final error fetching item \(id): \(error)")
            throw error
        }
    }

    /// Searches for items by name within the `static-classic1x` namespace.
    /// - Parameter name: The name of the item to search for.
    /// - Returns: An `ItemSearchResponse` containing the search results.
    /// - Throws: `AppError` or other errors if the search fails.
    func searchItems(name: String) async throws -> ItemSearchResponse {
        // Construct base query parameters for the search
        let params = [
            URLQueryItem(name: "name.\(locale)", value: name),
            URLQueryItem(name: "orderby", value: "id"),
            URLQueryItem(name: "_page", value: "1"),
        ]
        let searchEndpoint = Endpoint(path: "/data/wow/search/item", params: params)

        // Perform search only in the classic1x namespace
        do {
            // Fetch directly using the default namespace
            let response = try await fetch(ItemSearchResponse.self, endpoint: searchEndpoint)
            // No need to combine/deduplicate as we only search one namespace
            return response
        } catch AppError.badStatus(code: 404) {
            // A 404 on search likely means no results, return an empty response
            print("Search for '\(name)' returned 404 (no results found).")
            return ItemSearchResponse(
                page: 1, pageSize: 0, maxPageSize: 100, pageCount: 0, results: [])
        } catch {
            // Rethrow other errors
            print("Error searching items for '\(name)': \(error)")
            throw error
        }
        // REMOVED: Concurrent search across multiple namespaces and combining logic
    }

    // Class Endpoint
    func playableClass(id: Int) async throws -> PlayableClass {
        try await fetch(PlayableClass.self, endpoint: .init(path: "/data/wow/playable-class/\(id)"))
    }

    // Classes Index
    func playableClasses() async throws -> PlayableClassesIndex {
        try await fetch(
            PlayableClassesIndex.self, endpoint: .init(path: "/data/wow/playable-class/index"))
    }

    // Race Endpoint
    func playableRace(id: Int) async throws -> PlayableRace {
        try await fetch(PlayableRace.self, endpoint: .init(path: "/data/wow/playable-race/\(id)"))
    }

    // Races Index
    func playableRaces() async throws -> PlayableRacesIndex {
        try await fetch(
            PlayableRacesIndex.self, endpoint: .init(path: "/data/wow/playable-race/index"))
    }

    /// Fetches the media details (like icon URL) for a specific item using the `static-classic1x` namespace.
    /// - Parameter id: The ID of the item.
    /// - Returns: An `ItemMediaResponse` containing asset information.
    func fetchItemMedia(id: Int) async throws -> ItemMediaResponse {
        let endpoint = Endpoint(path: "/data/wow/media/item/\(id)")
        // Fetch using the default classic1x namespace
        return try await fetch(ItemMediaResponse.self, endpoint: endpoint)
    }

    // Item Class Index
    func itemClasses() async throws -> ItemClassesIndex {
        try await fetch(ItemClassesIndex.self, endpoint: .init(path: "/data/wow/item-class/index"))
    }

    // Item Class Detail
    func itemClass(id: Int) async throws -> ItemClassDetail {
        try await fetch(ItemClassDetail.self, endpoint: .init(path: "/data/wow/item-class/\(id)"))
    }

    // Item Subclass Detail
    func itemSubclass(classId: Int, subclassId: Int) async throws -> ItemSubclassDetail {
        try await fetch(
            ItemSubclassDetail.self,
            endpoint: .init(path: "/data/wow/item-class/\(classId)/item-subclass/\(subclassId)"))
    }

    // MARK: - Private Helpers

    /// Retrieves a valid OAuth access token, fetching a new one if necessary.
    private func getValidAccessToken() async throws -> String {
        // Check if current token exists and hasn't expired (with a small buffer)
        if let token = currentAccessToken, let expiry = tokenExpirationTime,
            expiry > Date().addingTimeInterval(60)
        {
            return token
        }

        // --- Fetch new token using Client Credentials Flow ---
        print("Fetching new OAuth token...")
        guard let url = URL(string: "https://\(region).battle.net/oauth/token") else {  // Corrected domain
            throw AppError.oauth("Invalid token endpoint URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        // Create credentials string
        guard let credentialsData = "\(clientID):\(clientSecret)".data(using: .utf8) else {
            throw AppError.oauth("Could not encode credentials")
        }
        let base64Credentials = credentialsData.base64EncodedString()
        request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        // Add grant_type parameter to body
        let body = "grant_type=client_credentials"
        request.httpBody = body.data(using: .utf8)

        // Make the request
        do {
            let (data, response) = try await ClassicAPIService.sharedSession.data(for: request)

            // Check response status
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200
            else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                print("OAuth token fetch failed with status: \(statusCode)")
                print("Response body: \(String(data: data, encoding: .utf8) ?? "N/A")")
                throw AppError.oauth("Token fetch failed with status \(statusCode)")
            }

            // Parse the response
            let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)

            // Store the new token and calculate expiration time
            self.currentAccessToken = tokenResponse.accessToken
            // expiresIn is in seconds, add it to the current date
            self.tokenExpirationTime = Date().addingTimeInterval(
                TimeInterval(tokenResponse.expiresIn))
            print("Successfully fetched new OAuth token.")
            return tokenResponse.accessToken

        } catch let error as AppError {
            // Rethrow AppError specifically
            throw error
        } catch {
            // Wrap other errors in AppError.oauth
            print("Error during OAuth token fetch: \(error)")
            throw AppError.oauth(
                "Token fetch network/decoding error: \(error.localizedDescription)")
        }
    }

    /// Structure to decode the OAuth token response.
    private struct TokenResponse: Codable {
        let accessToken: String
        let tokenType: String
        let expiresIn: Int  // Duration in seconds

        // Map snake_case keys from JSON to camelCase properties
        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case tokenType = "token_type"
            case expiresIn = "expires_in"
        }
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

/// Represents the overall response from an item search query.
struct ItemSearchResponse: Codable, Sendable {
    let page: Int
    let pageSize: Int
    let maxPageSize: Int
    let pageCount: Int
    let results: [ItemSearchResult]  // Array of search result items
}

/// Represents a single item found in a search result.
struct ItemSearchResult: Codable, Sendable, Identifiable {
    var id: Int {  // Use item ID as the identifiable ID
        return data.id
    }
    let data: ItemData  // Contains the core details of the item
    let key: KeyReference  // Reference to the full item endpoint

    /// Core data for an item within a search result.
    struct ItemData: Codable, Sendable {
        let id: Int
        let name: String
        let quality: Quality  // Item quality (e.g., Epic, Rare)
        let media: MediaReference  // Reference to the item's media (icon)
        // Add other fields if needed and available in the search response, like item_class, item_subclass, etc.
    }

    /// Reference to the full API endpoint for this item.
    struct KeyReference: Codable, Sendable {
        let href: String
    }

    /// Represents the quality of an item.
    struct Quality: Codable, Sendable {
        let type: String  // e.g., "EPIC", "RARE"
        let name: String  // Localized name, e.g., "Epic", "Rare"
    }

    /// Reference to the item's media asset (usually the icon).
    struct MediaReference: Codable, Sendable {
        let id: Int
        let key: KeyReference  // Reference to the media asset endpoint
    }
}

// MARK: - Media Response Structure

/// Represents the response from the item media endpoint.
struct ItemMediaResponse: Codable, Sendable {
    let assets: [MediaAsset]?  // Array of media assets (icon, etc.)
    let id: Int  // The ID of the item this media belongs to

    /// Represents a single media asset (like an icon).
    struct MediaAsset: Codable, Sendable {
        let key: String  // Type of asset, e.g., "icon"
        let value: String  // URL to the asset
        let fileDataId: Int?  // Optional file data ID
    }

    /// Helper function to extract the icon URL from the assets.
    /// - Returns: The URL string for the icon, or nil if not found.
    func getIconURL() -> String? {
        return assets?.first(where: { $0.key == "icon" })?.value
    }

    /// Helper function to extract the icon filename from the icon URL.
    /// Example: "https://render-us.worldofwarcraft.com/icons/56/inv_sword_39.jpg" -> "inv_sword_39"
    /// - Returns: The icon filename string, or nil if URL is not found or invalid.
    func getIconName() -> String? {
        guard let iconURLString = getIconURL(), let url = URL(string: iconURLString) else {
            return nil
        }
        // Get the last path component (e.g., "inv_sword_39.jpg")
        // Remove the file extension (e.g., ".jpg")
        return url.deletingPathExtension().lastPathComponent
    }
}
