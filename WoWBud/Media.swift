//
//  Media.swift
//  WoWBud
//
//  Created by Gunnar Hostetler on 6/17/25.
//

import Foundation

/// Represents media from the Blizzard API, which can either be a reference (key + id) or full assets.
struct Media: Codable, Hashable {
    let assets: [Asset]?  // Optional - only present when fetching from media endpoint
    let key: Link?        // Present when it's a reference to media
    let id: Int?          // Present when it's a reference to media
    
    /// Custom coding keys to handle both reference and full media responses
    enum CodingKeys: String, CodingKey {
        case assets, key, id
    }
    
    /// Custom decoder to handle both media reference and full media responses
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // These fields are optional depending on context
        assets = try container.decodeIfPresent([Asset].self, forKey: .assets)
        key = try container.decodeIfPresent(Link.self, forKey: .key)
        id = try container.decodeIfPresent(Int.self, forKey: .id)
    }
    
    /// Gets the icon filename from the assets
    /// - Returns: The icon filename (without extension) or nil if not found
    func getIconName() -> String? {
        guard let assets = assets,
              let iconAsset = assets.first(where: { $0.key == "icon" }) else {
            return nil
        }
        
        // Extract filename from URL
        let urlString = iconAsset.value
        if let url = URL(string: urlString) {
            let filename = url.deletingPathExtension().lastPathComponent
            return filename
        }
        
        return nil
    }
    
    /// Gets the media reference URL if this is a media reference
    /// - Returns: The href URL to fetch full media assets
    func getMediaReferenceURL() -> String? {
        return key?.href
    }
}

/// Represents a single media asset with a key (e.g., "icon") and a value (the URL).
struct Asset: Codable, Hashable {
    let key: String
    let value: String
}
