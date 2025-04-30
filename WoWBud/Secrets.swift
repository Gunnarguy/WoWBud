//
//  Secrets.swift
//  WoWClassicBuilder
//
//  Swift 6  –  strict-concurrency safe
//

import Foundation
import Security

/// Thin Keychain wrapper – replace the hard-coded strings only while debugging.
/// All static members are `Sendable` by synthesis.
enum Secrets: Sendable {
    /// Blizzard developer application’s Client ID
    static var clientID: String { cached("wow_client_id") ?? "<INSERT-CLIENT-ID>" }

    /// Blizzard developer application’s Client Secret
    static var clientSecret: String { cached("wow_client_secret") ?? "<INSERT-CLIENT-SECRET>" }

    /// Runtime OAuth token (client-credentials grant) set at launch
    static var oauthToken: String {
        get { cached("wow_oauth_token") ?? "" }
        set { store("wow_oauth_token", value: newValue) }
    }

    // MARK: - Keychain helpers

    /// Stores a string value securely in the Keychain.
    /// - Parameters:
    ///   - key: The unique key for the Keychain item.
    ///   - value: The string value to store.
    /// - Returns: True if the operation was successful, false otherwise.
    @discardableResult
    static func store(_ key: String, value: String) -> Bool {  // Make internal (default) to be accessible from SettingsView
        let data = Data(value.utf8)
        // Keychain query dictionary
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,  // Type of item
            kSecAttrAccount as String: key,  // Unique identifier
            kSecValueData as String: data,  // The data to store
        ]
        // Delete any existing item with the same key first to ensure overwrite
        SecItemDelete(query as CFDictionary)
        // Add the new item
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess  // Check if addition succeeded
    }

    /// Retrieves a string value from the Keychain.
    /// - Parameter key: The unique key for the Keychain item.
    /// - Returns: The stored string value, or nil if not found or on error.
    private static func cached(_ key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
            let data = item as? Data,
            let str = String(data: data, encoding: .utf8)
        else { return nil }
        return str
    }
}
