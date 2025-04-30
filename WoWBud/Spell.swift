//
//  Spell.swift
//

import Foundation

/// All value-types implicitly `Sendable` in Swift 6 when fields are Sendable.
public struct Spell: Codable, Hashable, Identifiable, Sendable {
    public let id: Int
    public let name: String
    public let description: String?
    public var baseCoefficient: Double?  // nullable – patch via ClassicDB

    public enum CodingKeys: String, CodingKey {
        case id, name, description
        case baseCoefficient = "spell_power_coefficient"
    }

    /// Scaled coefficient = c × SP × talentMod
    public func scaledCoefficient(spellPower: Double, talentMod: Double = 1) -> Double? {
        guard let base = baseCoefficient else { return nil }
        return base * spellPower * talentMod
    }
}
