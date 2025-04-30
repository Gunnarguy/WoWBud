//
//  PlayableRace.swift
//

import Foundation

struct PlayableRace: Codable, Hashable, Identifiable, Sendable {
    let id: Int
    let name: String
    let faction: String
    let isSelectable: Bool
}
