//
//  OAuth.swift
//  WoWBud
//
//  Created on 4/30/25.
//

import Foundation

/// A structure representing the response from a successful OAuth token request.
/// This is now a top-level struct to be accessible by services that use OAuth.
public struct TokenResponse: Decodable, Sendable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int // Seconds until token expires
    private let createdAt = Date() // Store creation date

    // Calculate the actual expiration date
    var isExpired: Bool {
        return Date() > createdAt.addingTimeInterval(TimeInterval(expiresIn))
    }

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
    }
}

/// Handles OAuth client credentials flow for the Blizzard API.
enum OAuth {
    /// Base URL for Blizzard OAuth endpoints
    private static let oauthURL = "https://us.battle.net/oauth/token"
    
    /// Fetches an OAuth token using client credentials grant.
    /// - Parameters:
    ///   - clientID: The Blizzard API client ID
    ///   - clientSecret: The Blizzard API client secret
    /// - Returns: A `TokenResponse` object containing the access token and its expiry time.
    static func fetchToken(clientID: String, clientSecret: String) async throws -> TokenResponse {
        // Create the URL
        guard let url = URL(string: oauthURL) else {
            throw AppError.invalidURL(oauthURL)
        }
        
        // Create the encoded Basic auth credentials (client_id:client_secret)
        let authString = "\(clientID):\(clientSecret)"
        guard let authData = authString.data(using: .utf8) else {
            throw AppError.oauth("Failed to encode authorization data")
        }
        let base64Auth = authData.base64EncodedString()
        
        // Create the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Basic \(base64Auth)", forHTTPHeaderField: "Authorization")
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // Add the form body with grant_type=client_credentials
        request.httpBody = "grant_type=client_credentials".data(using: .utf8)
        
        // Execute the request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check for valid HTTP response
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AppError.badStatus(code: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        
        // Decode the response
        do {
            let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
            return tokenResponse
        } catch {
            throw AppError.decodingFailure(entity: "OAuth Token", underlying: error)
        }
    }
}
