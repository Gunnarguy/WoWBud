//
//  Item.swift
//

import Foundation

struct Item: Codable, Hashable, Identifiable, Sendable {
    let id: Int
    let name: String
    let level: Int  // Item Level
    let quality: Quality  // Use a nested struct/enum for quality
    let inventoryType: InventoryType  // Use a nested struct/enum for inventory type
    let itemClass: ItemClass  // Use nested struct for item_class
    let itemSubclass: ItemSubclass  // Use nested struct for item_subclass
    let stats: [ItemStat]?  // Stats might be optional
    let requiredLevel: Int?  // Required level might not always be present
    let media: Media?  // For icon
    let purchasePrice: Int?  // Purchase price in copper
    let sellPrice: Int?  // Sell price in copper
    let maxCount: Int?  // Max stack count
    let isEquippable: Bool?
    let isStackable: Bool?
    let binding: Binding?  // Binding information
    let description: String?  // Flavor text
    let levelRequirement: LevelRequirement?  // Redundant? Check API response
    let nameDescription: String?  // e.g., "Heroic" - unlikely in Classic Era?
    let modifiedCraftingStat: ModifiedCraftingStat?  // Unlikely in Classic Era?
    let previewItem: PreviewItem?  // Contains detailed spell/stat info

    // MARK: - Nested Types

    // Moved DisplayString here to be accessible by multiple nested structs
    struct DisplayString: Codable, Hashable, Sendable {
        let displayString: String  // e.g., "+10 Intellect" or "123 Armor"
        let color: ColorInfo?

        struct ColorInfo: Codable, Hashable, Sendable {
            let r: Int
            let g: Int
            let b: Int
            let a: Double
        }
    }

    // Nested struct for Quality
    struct Quality: Codable, Hashable, Sendable {
        let type: String  // e.g., "EPIC"
        let name: String  // e.g., "Epic"
    }

    // Nested struct for InventoryType
    struct InventoryType: Codable, Hashable, Sendable {
        let type: String  // e.g., "NECK"
        let name: String  // e.g., "Neck"
    }

    // Nested struct for ItemClass
    struct ItemClass: Codable, Hashable, Sendable {
        let key: Link?  // Optional link
        let name: String  // e.g., "Armor"
        let id: Int
    }

    // Nested struct for ItemSubclass
    struct ItemSubclass: Codable, Hashable, Sendable {
        let key: Link?  // Optional link
        let name: String  // e.g., "Cloth"
        let id: Int
    }

    // Nested struct for ItemStat - Adjusted based on typical API structure
    struct ItemStat: Codable, Hashable, Sendable {
        let type: StatType  // Nested type for stat details
        let value: Int
        let display: DisplayString?  // Use Item.DisplayString
        let isNegated: Bool?  // Optional flag
        let isEquipBonus: Bool?  // Optional flag

        struct StatType: Codable, Hashable, Sendable {
            let type: String  // e.g., "INTELLECT"
            let name: String  // e.g., "Intellect"
        }
    }

    // Nested struct for Media (Icon)
    struct Media: Codable, Hashable, Sendable {
        let key: Link?
        let id: Int
        // We need the actual icon URL, which might be under 'assets' in a separate media call
        // Or sometimes it's directly provided. Let's assume we need to fetch it separately or construct it.
        // Add 'assets' if the main item endpoint includes it.
        let assets: [Asset]?  // Check if this exists in the item response

        struct Asset: Codable, Hashable, Sendable {
            let key: String  // e.g., "icon"
            let value: String  // The actual URL
            let fileDataId: Int?
        }
    }

    // Nested struct for Binding
    struct Binding: Codable, Hashable, Sendable {
        let type: String  // e.g., "ON_ACQUIRE"
        let name: String  // e.g., "Binds when picked up"
    }

    // Nested struct for LevelRequirement (if needed)
    struct LevelRequirement: Codable, Hashable, Sendable {
        let value: Int
        let displayString: String  // e.g., "Requires Level 60"
    }

    // Nested struct for Link (common in Blizzard API)
    struct Link: Codable, Hashable, Sendable {
        let href: String
    }

    // Nested struct for PreviewItem (contains detailed stats, spells)
    struct PreviewItem: Codable, Hashable, Sendable {
        // Define a struct to match the nested 'item' object structure
        struct ItemReference: Codable, Hashable, Sendable {
            let key: Link?
            let id: Int
        }

        let item: ItemReference?  // Changed type from Link? to ItemReference?
        let quality: Quality?
        let name: String?
        let media: Media?
        let itemClass: ItemClass?
        let itemSubclass: ItemSubclass?
        let inventoryType: InventoryType?
        let binding: Binding?
        let armor: Armor?
        let stats: [ItemStat]?
        let spells: [ItemSpell]?
        let sellPrice: SellPrice?
        let requirements: Requirements?
        let level: Level?  // Item level
        let description: String?  // Flavor text
        let durability: Durability?  // Added durability
        let weapon: Weapon?  // Added weapon details

        // Conformance should now be synthesized correctly as Item.DisplayString conforms
        struct Armor: Codable, Hashable, Sendable {
            let value: Int
            let display: DisplayString?  // Use Item.DisplayString
        }

        // Moved DamageStat struct definition here (outside of Weapon)
        // New struct specifically for weapon damage
        struct DamageStat: Codable, Hashable, Sendable {
            // Swift properties using camelCase - should now be automatically mapped
            // by the global .convertFromSnakeCase strategy in ClassicAPIService
            let minValue: Int
            let maxValue: Int
            let displayString: String
            // TEMPORARILY REMOVED: Optional damage class info to simplify decoding
            // let damageClass: DamageClass?

            // REMOVED: Explicit CodingKeys enum. Relying solely on global .convertFromSnakeCase.

            // REMOVED: Nested struct for damage class (as property is removed)
            // struct DamageClass: Codable, Hashable, Sendable {
            //     let type: String
            //     let name: String
            // }
        }

        struct ItemSpell: Codable, Hashable, Sendable {
            let spell: SpellReference?
            let description: String?  // e.g., "Equip: Increases damage and healing done..."

            struct SpellReference: Codable, Hashable, Sendable {
                let key: Link?
                let name: String?
                let id: Int
            }
        }

        struct SellPrice: Codable, Hashable, Sendable {
            let value: Int  // Price in copper
            let displayStrings: DisplayStrings?

            struct DisplayStrings: Codable, Hashable, Sendable {
                let header: String?  // e.g., "Sell Price:"
                let gold: String?
                let silver: String?
                let copper: String?
            }
        }

        struct Requirements: Codable, Hashable, Sendable {
            let level: Level?
            let playableClasses: PlayableClasses?  // If class restricted

            struct PlayableClasses: Codable, Hashable, Sendable {
                let links: [ClassLink]?
                let displayString: String?  // e.g., "Classes: Mage"

                struct ClassLink: Codable, Hashable, Sendable {
                    let key: Link?
                    let name: String?
                    let id: Int
                }
            }
        }

        struct Level: Codable, Hashable, Sendable {
            let value: Int
            let displayString: String?  // e.g., "Requires Level 60" or "Item Level 70"
        }

        // Added Durability struct
        struct Durability: Codable, Hashable, Sendable {
            let value: Int
            let displayString: String?  // e.g., "Durability 100 / 100"
        }

        // Added Weapon struct
        struct Weapon: Codable, Hashable, Sendable {
            let damage: DamageStat?  // Use the new DamageStat struct (now defined outside)
            let attackSpeed: WeaponStat?
            let dps: WeaponStat?

            // REMOVED: DamageStat struct definition moved outside Weapon

            // Existing struct for attack speed and dps
            struct WeaponStat: Codable, Hashable, Sendable {
                let value: Double  // Use Double for potential floating point values (like speed/dps)
                let displayString: String  // e.g., "1.50" or "35.3" or "37 - 69 Damage"

                // REMOVED: Explicit CodingKeys. Rely on global .convertFromSnakeCase.
                // enum CodingKeys: String, CodingKey {
                //     case value  // No mapping needed if .convertFromSnakeCase is used
                //     case displayString = "display_string"
                // }
            }
        }
    }

    // Placeholder structs for potential future fields if needed
    struct ModifiedCraftingStat: Codable, Hashable, Sendable {}

    // MARK: - Helper Functions

    // Helper to get icon URL (assuming 'assets' structure)
    func getIconURL() -> String? {
        return media?.assets?.first(where: { $0.key == "icon" })?.value
    }

    // Helper to get primary quality name (e.g., "Epic")
    func getQualityName() -> String {
        return quality.name
    }

    // Helper to get primary quality type (e.g., "EPIC")
    func getQualityType() -> String {
        return quality.type
    }

    // Helper to get inventory type name (e.g., "Neck")
    func getInventoryTypeName() -> String {
        return inventoryType.name
    }

    // Helper to get item class name (e.g., "Armor")
    func getItemClassName() -> String {
        return itemClass.name
    }

    // Helper to get item subclass name (e.g., "Cloth")
    func getItemSubclassName() -> String {
        return itemSubclass.name
    }

    // Helper to get binding string (e.g., "Binds when picked up")
    func getBindingString() -> String? {
        return previewItem?.binding?.name ?? binding?.name
    }

    // Helper to get formatted stats from preview_item
    func getFormattedStats() -> [String] {
        guard let previewStats = previewItem?.stats else { return [] }
        return previewStats.compactMap { $0.display?.displayString }
    }

    // Helper to get formatted spells/effects from preview_item
    func getFormattedSpells() -> [String] {
        guard let previewSpells = previewItem?.spells else { return [] }
        return previewSpells.compactMap { $0.description }
    }

    // Helper to get required level display string
    func getRequiredLevelString() -> String? {
        return previewItem?.requirements?.level?.displayString ?? levelRequirement?.displayString
    }

    // Helper to get required classes display string
    func getRequiredClassesString() -> String? {
        return previewItem?.requirements?.playableClasses?.displayString
    }

    // Helper to get sell price in copper
    func getSellPriceCopper() -> Int? {
        return previewItem?.sellPrice?.value ?? sellPrice
    }

    // Helper to get item level
    func getItemLevel() -> Int {
        return previewItem?.level?.value ?? level
    }

    // Helper to get durability value
    func getDurabilityValue() -> Int? {
        return previewItem?.durability?.value
    }

    // Helper to get weapon damage string
    func getWeaponDamageString() -> String? {
        // Access displayString from the new DamageStat struct
        return previewItem?.weapon?.damage?.displayString
    }

    // Helper to get weapon attack speed string
    func getWeaponAttackSpeedString() -> String? {
        return previewItem?.weapon?.attackSpeed?.displayString
    }

    // Helper to get weapon dps string
    func getWeaponDpsString() -> String? {
        return previewItem?.weapon?.dps?.displayString
    }
}