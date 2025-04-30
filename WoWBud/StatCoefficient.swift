//
//  StatCoefficient.swift
//

import Foundation

struct StatCoefficient: Codable, Hashable, Sendable {
    let statID: Int
    let coefficient: Double
    let comment: String?
}
