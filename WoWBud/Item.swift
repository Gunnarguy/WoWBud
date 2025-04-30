//
//  Item.swift
//

import Foundation

struct Item: Codable, Hashable, Identifiable, Sendable {
    let id: Int
    let name: String
    let level: Int
    let quality: Int
    let inventoryType: Int
    let stats: [ItemStat]

    struct ItemStat: Codable, Hashable, Sendable {
        let type: Int
        let value: Int
    }
}
