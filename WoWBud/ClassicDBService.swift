//
//  ClassicDBService.swift
//  WoWClassicBuilder
//
//  Swift 6 – isolated actor; GRDB use remains local to the actor.
//  Note: GRDB’s `DatabaseQueue` isn’t `Sendable`; we keep it fully actor-isolated.
//

import Foundation
import GRDB

actor ClassicDBService {

    // MARK: - Singleton
    static let shared = ClassicDBService()

    // MARK: - Private DB
    private let dbQueue: DatabaseQueue

    init() {
        let url = try! FileManager.default
            .url(
                for: .applicationSupportDirectory,
                in: .userDomainMask, appropriateFor: nil, create: true
            )
            .appendingPathComponent("ClassicDB.sqlite")
        dbQueue = try! DatabaseQueue(path: url.path)
    }

    // MARK: - API (async/await)

    /// Fetches the direct spell bonus coefficient for a given spell ID.
    /// - Parameter id: The spell ID.
    /// - Returns: The direct bonus coefficient (zero if not found or error).
    func spellBonusCoefficient(id: Int) async throws -> Double {
        // Perform a synchronous read within actor isolation
        let bonusOpt: Double? = try await dbQueue.read { db in
            try Double.fetchOne(
                db,
                sql: "SELECT direct_bonus FROM spell_bonus_data WHERE spellID = ?",
                arguments: [id])
        }
        return bonusOpt ?? 0
    }

    /// Fetches all item stat rows for a given item ID.
    func itemStats(for id: Int) async throws -> [Row] {
        // Synchronous read under actor isolation
        let rows: [Row] = try dbQueue.read { db in
            try Row.fetchAll(
                db,
                sql: "SELECT stat_type, value FROM item_stats WHERE itemID = ?",
                arguments: [id])
        }
        return rows
    }
}
