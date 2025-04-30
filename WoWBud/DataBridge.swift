//
//  DataBridge.swift
//  WoWClassicBuilder
//
//  Swift 6 – actor orchestrating remote + local sources.
//

import Foundation

actor DataBridge {

    static let shared = DataBridge()

    private let remote = BlizzardAPIService()
    private let local = ClassicDBService.shared
    private let store = PersistenceController.shared

    /// Refresh single spell, merging ClassicDB gaps.
    func refreshSpell(id: Int) async throws {
        // 1. Pull authoritative API spell
        var spell = try await remote.spell(id: id)

        // 2. Fill missing coefficient from DB if needed
        if spell.baseCoefficient == nil {
            // Fetch the coefficient directly as Double?
            let coefficient = try await local.spellBonusCoefficient(id: id)
            spell.baseCoefficient = coefficient  // Assign if found, otherwise remains nil
        }

        // 3. Persist
        try await store.save(spell: spell)
    }

    /// Monte-Carlo completeness audit – returns coverage fraction.
    /// Samples random spell IDs to check if data exists either remotely or locally.
    func nightlyAudit(sample: Int = 1_000) async -> Double {
        let maxID = 5_000  // Assuming max relevant spell ID
        var filled = 0
        var rng = SystemRandomNumberGenerator()  // Create RNG instance here

        for _ in 0..<sample {
            let id = Int.random(in: 1...maxID, using: &rng)  // Pass rng as inout

            // Concurrently check both remote API and local DB for the spell data
            async let remoteHasData = (try? await remote.spell(id: id))?.baseCoefficient != nil
            async let localHasData = (try? await local.spellBonusCoefficient(id: id)) != nil

            // Await the results of the concurrent checks
            let hasRemote = await remoteHasData
            let hasLocal = await localHasData

            // Consider filled if either source has data
            if hasRemote || hasLocal {
                filled += 1
            }
        }
        // Return the fraction of sampled IDs that had data
        return Double(filled) / Double(sample)
    }
}
