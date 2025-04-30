//
//  PersistenceController.swift
//
//  Swift 6 – CoreData isolated inside an actor.
//

import CoreData
import Foundation  // Required for Spell type

actor PersistenceController {

    static let shared = PersistenceController()

    private let container: NSPersistentContainer

    private init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "WoWClassicBuilder")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, err in
            if let err { fatalError("CoreData failed: \(err)") }
        }
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // MARK: – Write helpers (called from other actors with `await`)
    /// Persist a Spell asynchronously into Core Data.
    func save(spell: Spell) async throws {
        try await withCheckedThrowingContinuation { cont in
            container.performBackgroundTask { ctx in
                let obj = CDSpell(context: ctx)
                obj.id = Int32(spell.id)
                obj.name = spell.name
                obj.desc = spell.description
                obj.baseCoefficient = spell.baseCoefficient ?? 0
                do {
                    try ctx.save()
                    cont.resume()
                } catch {
                    cont.resume(throwing: error)
                }
            }
        }
    }

    // TODO: Add save(item:), etc.
}

// MARK: - Core Data Managed Object Subclass for 'CDSpell'
@objc(CDSpell)
public class CDSpell: NSManagedObject {
    /// Unique identifier for the spell
    @NSManaged public var id: Int32
    /// Spell name
    @NSManaged public var name: String?
    /// Spell description text
    @NSManaged public var desc: String?
    /// Base coefficient as stored in Core Data
    @NSManaged public var baseCoefficient: Double
}
