//
//  PlayableClass.swift
//

import Foundation

struct PlayableClass: Codable, Hashable, Identifiable, Sendable {
    let id: Int
    let name: String
    let powerType: String
}
