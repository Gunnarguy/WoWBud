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

    // MARK: - Helper Functions

    // Helper to get icon URL (handles both asset-based and reference-based media)
    func getIconURL() -> String? {
        // First try to get from assets if available
        if let iconURL = media?.assets?.first(where: { $0.key == "icon" })?.value {
            return iconURL
        }
        
        // Fallback to preview_item media assets if available
        return previewItem?.media?.assets?.first(where: { $0.key == "icon" })?.value
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
