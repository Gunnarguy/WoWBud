//
//  TalentTree.swift
//

import Foundation

struct TalentTree: Codable, Hashable, Sendable {
    struct Node: Codable, Hashable, Identifiable, Sendable {
        let id: Int
        let spellID: Int
        let tier: Int
        let column: Int
        let ranks: Int
    }

    let classID: Int
    let nodes: [Node]
}
