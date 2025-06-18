import Foundation

// MARK: - Shared Nested Types (now top-level)

struct DisplayString: Codable, Hashable, Sendable {
    let displayString: String
    let color: ColorInfo?

    struct ColorInfo: Codable, Hashable, Sendable {
        let r: Int
        let g: Int
        let b: Int
        let a: Double
    }
}

struct Quality: Codable, Hashable, Sendable {
    let type: String
    let name: String
}

struct InventoryType: Codable, Hashable, Sendable {
    let type: String
    let name: String
}

struct ItemClass: Codable, Hashable, Sendable {
    let key: Link?
    let name: String
    let id: Int
}

struct ItemSubclass: Codable, Hashable, Sendable {
    let key: Link?
    let name: String
    let id: Int
}

struct ItemStat: Codable, Hashable, Sendable {
    let type: StatType
    let value: Int
    let display: DisplayString?
    let isNegated: Bool?
    let isEquipBonus: Bool?

    struct StatType: Codable, Hashable, Sendable {
        let type: String
        let name: String
    }
}

struct Binding: Codable, Hashable, Sendable {
    let type: String
    let name: String
}

struct LevelRequirement: Codable, Hashable, Sendable {
    let value: Int
    let displayString: String
}

struct Link: Codable, Hashable, Sendable {
    let href: String
}

struct PreviewItem: Codable, Hashable, Sendable {
    struct ItemReference: Codable, Hashable, Sendable {
        let key: Link?
        let id: Int
    }

    let item: ItemReference?
    let quality: Quality?
    let name: String?
    let media: Media?  // Media reference for the preview item
    let itemClass: ItemClass?
    let itemSubclass: ItemSubclass?
    let inventoryType: InventoryType?
    let binding: Binding?
    let armor: Armor?
    let stats: [ItemStat]?
    let spells: [ItemSpell]?
    let sellPrice: SellPrice?
    let requirements: Requirements?
    let level: Level?
    let description: String?
    let durability: Durability?
    let weapon: Weapon?

    struct Armor: Codable, Hashable, Sendable {
        let value: Int
        let display: DisplayString?
    }

    struct DamageStat: Codable, Hashable, Sendable {
        let minValue: Int
        let maxValue: Int
        let displayString: String
    }

    struct ItemSpell: Codable, Hashable, Sendable {
        let spell: SpellReference?
        let description: String?

        struct SpellReference: Codable, Hashable, Sendable {
            let key: Link?
            let name: String?
            let id: Int
        }
    }

    struct SellPrice: Codable, Hashable, Sendable {
        let value: Int
        let displayStrings: DisplayStrings?

        struct DisplayStrings: Codable, Hashable, Sendable {
            let header: String?
            let gold: String?
            let silver: String?
            let copper: String?
        }
    }

    struct Requirements: Codable, Hashable, Sendable {
        let level: Level?
        let playableClasses: PlayableClasses?

        struct PlayableClasses: Codable, Hashable, Sendable {
            let links: [ClassLink]?
            let displayString: String?

            struct ClassLink: Codable, Hashable, Sendable {
                let key: Link?
                let name: String?
                let id: Int
            }
        }
    }

    struct Level: Codable, Hashable, Sendable {
        let value: Int
        let displayString: String?
    }

    struct Durability: Codable, Hashable, Sendable {
        let value: Int
        let displayString: String?
    }

    struct Weapon: Codable, Hashable, Sendable {
        let damage: DamageStat?
        let attackSpeed: WeaponStat?
        let dps: WeaponStat?

        struct WeaponStat: Codable, Hashable, Sendable {
            let value: Double
            let displayString: String
        }
    }
}

struct ModifiedCraftingStat: Codable, Hashable, Sendable {}
