//
//  ItemLookupView.swift
//  WoWBud
//
//  Created on 4/30/25.
//

import SwiftUI

struct ItemLookupView: View {
    // State for the input
    @State private var searchText: String = ""
    @State private var searchMode: SearchMode = .itemID

    // State to hold the fetched data
    @State private var item: ClassicItem? = nil
    @State private var searchResults: [ClassicItemPreview] = []

    // State for displaying error messages
    @State private var errorMessage: String? = nil

    // State to indicate loading activity
    @State private var isLoading: Bool = false

    // Recently viewed items
    @State private var recentItems: [ClassicItemPreview] = []

    // Popular phase 1 items (mock data)
    private let phase1Items: [ClassicItemPreview] = [
        ClassicItemPreview(
            id: 18832, name: "Brutality Blade", quality: 4, iconName: "inv_sword_43"),
        ClassicItemPreview(
            id: 18803, name: "Finkle's Lava Dredger", quality: 4, iconName: "inv_hammer_22"),
        ClassicItemPreview(
            id: 18814, name: "Choker of the Fire Lord", quality: 4,
            iconName: "inv_jewelry_necklace_07"),
        ClassicItemPreview(
            id: 18821, name: "Quick Strike Ring", quality: 4, iconName: "inv_jewelry_ring_24"),
        ClassicItemPreview(
            id: 16800, name: "Arcanist Crown", quality: 4, iconName: "inv_helmet_66"),
        ClassicItemPreview(
            id: 16858, name: "Lawbringer Chestguard", quality: 4, iconName: "inv_chest_plate03"),
        ClassicItemPreview(
            id: 16865, name: "Breastplate of Might", quality: 4, iconName: "inv_chest_plate16"),
        ClassicItemPreview(
            id: 18264, name: "Plans: Elemental Sharpening Stone", quality: 1,
            iconName: "inv_scroll_03"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                // Search mode picker
                Picker("", selection: $searchMode) {
                    Text("ID").tag(SearchMode.itemID)
                    Text("Name").tag(SearchMode.itemName)
                }
                .pickerStyle(.segmented)
                .frame(width: 100)

                // Search text field
                TextField(
                    searchMode == .itemID ? "Enter Item ID" : "Enter Item Name", text: $searchText
                )
                .padding(8)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
                .keyboardType(searchMode == .itemID ? .numberPad : .default)
                .onSubmit {
                    hideKeyboard()
                    performSearch()
                }
                .submitLabel(searchMode == .itemID ? .search : .done)

                // Search button
                Button(action: {
                    hideKeyboard()
                    performSearch()
                }) {
                    Image(systemName: "magnifyingglass")
                        .padding(8)
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .disabled(searchText.isEmpty || isLoading)
            }
            .padding()

            // Content area
            ScrollView {
                // Loading indicator
                if isLoading {
                    ProgressView("Loading...")
                        .padding()
                }
                // Error message
                else if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                // Item detail
                else if let item = item {
                    itemDetailView(item)
                }
                // Search results
                else if !searchResults.isEmpty {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        Text("Search Results")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(searchResults) { itemPreview in
                            Button(action: {
                                loadItem(id: itemPreview.id)
                            }) {
                                itemPreviewRow(itemPreview)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                }
                // Initial/empty state
                else {
                    defaultContentView
                }
            }
        }
        .navigationTitle("Classic Item Database")
        .onAppear {
            // Load recent items from UserDefaults
            loadRecentItems()
        }
        // Add tap gesture to dismiss keyboard when tapping outside text field
        .contentShape(Rectangle())
        .onTapGesture {
            hideKeyboard()
        }
    }

    // MARK: - Subviews

    /// Default content view shown when no search is performed
    private var defaultContentView: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Phase 1 popular items
            VStack(alignment: .leading, spacing: 16) {
                Text("Molten Core Highlights")
                    .font(.headline)
                    .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(phase1Items) { itemPreview in
                            Button(action: {
                                loadItem(id: itemPreview.id)
                            }) {
                                itemCard(itemPreview)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                }
            }

            // Recently viewed items
            if !recentItems.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Recently Viewed")
                        .font(.headline)
                        .padding(.horizontal)

                    ForEach(recentItems.prefix(5)) { itemPreview in
                        Button(action: {
                            loadItem(id: itemPreview.id)
                        }) {
                            itemPreviewRow(itemPreview)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
            }

            // Search tips
            VStack(alignment: .leading, spacing: 8) {
                Text("Search Tips")
                    .font(.headline)

                Text("• Search by item ID for exact matches")
                Text("• Search by name for multiple results")
                Text("• Tap on items to view full details")
                Text("• Phase 2 items available Dec 12")
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
            .padding()
        }
        .padding(.top)
    }

    /// Card view for item preview
    private func itemCard(_ itemPreview: ClassicItemPreview) -> some View {
        VStack(spacing: 8) {
            // Item icon
            itemIconView(iconName: itemPreview.iconName, quality: itemPreview.quality)
                .frame(width: 60, height: 60)

            // Item name
            Text(itemPreview.name)
                .font(.caption)
                .foregroundColor(qualityColor(itemPreview.quality))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 100)
        }
        .padding(8)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }

    /// Row view for item preview in lists
    private func itemPreviewRow(_ itemPreview: ClassicItemPreview) -> some View {
        HStack(spacing: 12) {
            // Item icon
            itemIconView(iconName: itemPreview.iconName, quality: itemPreview.quality)
                .frame(width: 40, height: 40)

            // Item details
            VStack(alignment: .leading, spacing: 4) {
                Text(itemPreview.name)
                    .font(.headline)
                    .foregroundColor(qualityColor(itemPreview.quality))

                Text("Item ID: \(itemPreview.id)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
        .padding(.horizontal)
    }

    /// View for detailed item information
    private func itemDetailView(_ item: ClassicItem) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Item header
            HStack(spacing: 16) {
                // Item icon
                itemIconView(iconName: item.iconName, quality: item.quality)
                    .frame(width: 64, height: 64)

                // Item name and basic info
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.headline)
                        .foregroundColor(qualityColor(item.quality))

                    if let itemType = item.itemType, let itemSubType = item.itemSubType {
                        Text("\(itemType) • \(itemSubType)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    if let bindType = item.bindType {
                        Text(bindType)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Item level badge
                if let itemLevel = item.itemLevel {
                    Text("iLvl \(itemLevel)")
                        .font(.caption)
                        .padding(6)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(6)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)

            // Item stats
            if !item.stats.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Stats")
                        .font(.headline)

                    ForEach(item.stats, id: \.self) { stat in
                        Text(stat)
                            .font(.body)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
            }

            // Item effects/procs
            if let itemSpells = item.itemSpells, !itemSpells.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Effects")
                        .font(.headline)

                    ForEach(itemSpells, id: \.self) { spell in
                        Text(spell)
                            .font(.body)
                            .foregroundColor(.green)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
            }

            // Source information
            if let sources = item.sources, !sources.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sources")
                        .font(.headline)

                    ForEach(sources, id: \.self) { source in
                        HStack {
                            Image(systemName: "location")
                                .foregroundColor(.blue)

                            Text(source)
                                .font(.body)
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
            }

            // Item requirements
            if item.requiredLevel > 0 || item.requiredClasses != nil {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Requirements")
                        .font(.headline)

                    if item.requiredLevel > 0 {
                        Text("Required Level: \(item.requiredLevel)")
                            .font(.body)
                    }

                    if let classes = item.requiredClasses {
                        Text("Classes: \(classes)")
                            .font(.body)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
            }

            // Vendor info
            if let sellPrice = item.sellPrice, sellPrice > 0 {
                HStack {
                    Text("Vendor Sell:")
                        .font(.headline)

                    Spacer()

                    // Format gold, silver, copper
                    let gold = sellPrice / 10000
                    let silver = (sellPrice % 10000) / 100
                    let copper = sellPrice % 100

                    if gold > 0 {
                        Text("\(gold)g")
                            .font(.body)
                            .foregroundColor(.yellow)
                    }

                    if silver > 0 {
                        Text("\(silver)s")
                            .font(.body)
                            .foregroundColor(.gray)
                    }

                    if copper > 0 {
                        Text("\(copper)c")
                            .font(.body)
                            .foregroundColor(.orange)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
            }

            // Item ID
            HStack {
                Text("Item ID:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("\(item.id)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                // Share button
                Button(action: {
                    // Share item info
                    let shareText = "Check out this Classic WoW item: \(item.name) (ID: \(item.id))"
                    let activityVC = UIActivityViewController(
                        activityItems: [shareText],
                        applicationActivities: nil
                    )

                    // Present the share sheet
                    if let windowScene = UIApplication.shared.connectedScenes.first
                        as? UIWindowScene,
                        let rootViewController = windowScene.windows.first?.rootViewController
                    {
                        rootViewController.present(activityVC, animated: true)
                    }
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.blue)
                }
            }
            .padding()
        }
        .padding()
    }

    /// View for item icon with quality border
    private func itemIconView(iconName: String, quality: Int) -> some View {
        // In a real app, you would load the actual icon from API or assets
        // For now, using a placeholder with color based on quality
        ZStack {
            // Quality border
            RoundedRectangle(cornerRadius: 6)
                .stroke(qualityColor(quality), lineWidth: 2)
                .background(Color.black.cornerRadius(6))

            // Icon placeholder
            Text(String(iconName.prefix(1)).uppercased())
                .font(.headline)
                .foregroundColor(.white)
        }
    }

    // MARK: - Functionality

    /// Perform search based on current mode
    private func performSearch() {
        guard !searchText.isEmpty else { return }

        isLoading = true
        errorMessage = nil
        searchResults = []
        item = nil

        if searchMode == .itemID {
            // Search by item ID
            guard let itemID = Int(searchText) else {
                errorMessage = "Please enter a valid item ID"
                isLoading = false
                return
            }

            loadItem(id: itemID)
        } else {
            // Search by item name
            // In a real app, this would call an API
            // For now, simulate with mock data
            simulateNameSearch(name: searchText)
        }
    }

    /// Load item by ID
    private func loadItem(id: Int) {
        isLoading = true
        errorMessage = nil
        searchResults = []
        item = nil

        // In a real app, this would use ClassicAPIService
        // For now, simulate with mock data
        simulateItemLoad(id: id)
    }

    /// Simulate item loading (mock data)
    private func simulateItemLoad(id: Int) {
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            // Check if it's one of our mock items
            let mockItem = self.getMockItem(id: id)

            if let mockItem = mockItem {
                self.item = mockItem

                // Add to recent items
                self.addToRecentItems(
                    ClassicItemPreview(
                        id: mockItem.id,
                        name: mockItem.name,
                        quality: mockItem.quality,
                        iconName: mockItem.iconName
                    ))
            } else {
                self.errorMessage = "Item not found. Try another ID."
            }

            self.isLoading = false
        }
    }

    /// Simulate name search (mock data)
    private func simulateNameSearch(name: String) {
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            // Mock search results
            let lowerName = name.lowercased()
            let results = self.phase1Items.filter {
                $0.name.lowercased().contains(lowerName)
            }

            if results.isEmpty {
                self.errorMessage = "No items found matching '\(name)'"
            } else {
                self.searchResults = results
            }

            self.isLoading = false
        }
    }

    /// Get mock item by ID
    private func getMockItem(id: Int) -> ClassicItem? {
        // For demo purposes, just create mock items for our phase1Items list
        if let preview = phase1Items.first(where: { $0.id == id }) {
            // Create a detailed item from the preview
            return createMockDetailedItem(from: preview)
        }

        return nil
    }

    /// Create a detailed item from a preview (mock data)
    private func createMockDetailedItem(from preview: ClassicItemPreview) -> ClassicItem {
        var itemType: String?
        var itemSubType: String?
        var bindType: String?
        var itemLevel: Int?
        var requiredLevel: Int = 0
        var requiredClasses: String?
        var sellPrice: Int?
        var stats: [String] = []
        var itemSpells: [String] = []
        var sources: [String] = []

        // Create mock data based on item ID
        switch preview.id {
        case 18832:  // Brutality Blade
            itemType = "Weapon"
            itemSubType = "One-Handed Sword"
            bindType = "Binds when picked up"
            itemLevel = 70
            requiredLevel = 60
            sellPrice = 15876
            stats = [
                "+9 Strength",
                "+9 Agility",
                "Damage: 86-161",
                "Speed: 2.50",
                "DPS: 49.4",
            ]
            sources = ["Molten Core - Garr", "Molten Core - Baron Geddon"]

        case 18803:  // Finkle's Lava Dredger
            itemType = "Weapon"
            itemSubType = "Two-Handed Mace"
            bindType = "Binds when picked up"
            itemLevel = 70
            requiredLevel = 60
            sellPrice = 23948
            stats = [
                "+12 Strength",
                "+22 Stamina",
                "Damage: 223-335",
                "Speed: 3.40",
                "DPS: 82.1",
            ]
            sources = ["Molten Core - Ragnaros"]

        case 18814:  // Choker of the Fire Lord
            itemType = "Armor"
            itemSubType = "Neck"
            bindType = "Binds when picked up"
            itemLevel = 78
            requiredLevel = 60
            sellPrice = 11422
            stats = [
                "+10 Stamina",
                "+22 Intellect",
                "+33 Spell Power",
            ]
            sources = ["Molten Core - Ragnaros"]

        case 18821:  // Quick Strike Ring
            itemType = "Armor"
            itemSubType = "Finger"
            bindType = "Binds when picked up"
            itemLevel = 67
            requiredLevel = 60
            sellPrice = 8945
            stats = [
                "+5 Stamina",
                "+5 Strength",
                "+30 Attack Power",
            ]
            itemSpells = ["Equip: Improves your chance to hit by 1%."]
            sources = ["Molten Core - Golemagg the Incinerator"]

        case 16800:  // Arcanist Crown
            itemType = "Armor"
            itemSubType = "Cloth Head"
            bindType = "Binds when picked up"
            itemLevel = 66
            requiredLevel = 60
            requiredClasses = "Mage"
            sellPrice = 9854
            stats = [
                "+20 Intellect",
                "+10 Stamina",
                "+12 Spell Power",
            ]
            itemSpells = [
                "Set: (8) pieces - Increases the critical strike damage bonus of your Arcane and Fire spells by 3%."
            ]
            sources = ["Molten Core - Various bosses"]

        case 16858:  // Lawbringer Chestguard
            itemType = "Armor"
            itemSubType = "Plate Chest"
            bindType = "Binds when picked up"
            itemLevel = 66
            requiredLevel = 60
            requiredClasses = "Paladin"
            sellPrice = 10298
            stats = [
                "+17 Strength",
                "+17 Stamina",
                "+11 Intellect",
            ]
            itemSpells = [
                "Set: (8) pieces - Your Flash of Light has a 25% chance to restore 60 mana when cast."
            ]
            sources = ["Molten Core - Various bosses"]

        case 16865:  // Breastplate of Might
            itemType = "Armor"
            itemSubType = "Plate Chest"
            bindType = "Binds when picked up"
            itemLevel = 66
            requiredLevel = 60
            requiredClasses = "Warrior"
            sellPrice = 10298
            stats = [
                "+27 Strength",
                "+17 Stamina",
            ]
            itemSpells = [
                "Set: (8) pieces - Your Defensive Stance now reduces damage taken by an additional 5%."
            ]
            sources = ["Molten Core - Various bosses"]

        case 18264:  // Plans: Elemental Sharpening Stone
            itemType = "Recipe"
            itemSubType = "Blacksmithing"
            bindType = "Binds when picked up"
            itemLevel = 1
            requiredLevel = 0
            sellPrice = 100
            itemSpells = ["Teaches you how to make an Elemental Sharpening Stone."]
            sources = ["Molten Core - Trash mobs"]

        default:
            // Default values for unknown items
            itemType = "Unknown"
            itemSubType = "Miscellaneous"
            bindType = "Unknown"
            itemLevel = 1
            requiredLevel = 1
            sellPrice = 0
            stats = []
            sources = ["Unknown source"]
        }

        return ClassicItem(
            id: preview.id,
            name: preview.name,
            quality: preview.quality,
            iconName: preview.iconName,
            itemType: itemType,
            itemSubType: itemSubType,
            bindType: bindType,
            itemLevel: itemLevel,
            requiredLevel: requiredLevel,
            requiredClasses: requiredClasses,
            sellPrice: sellPrice,
            stats: stats,
            itemSpells: itemSpells,
            sources: sources
        )
    }

    /// Get color for item quality
    private func qualityColor(_ quality: Int) -> Color {
        switch quality {
        case 0: return .gray  // Poor
        case 1: return .white  // Common
        case 2: return .green  // Uncommon
        case 3: return .blue  // Rare
        case 4: return .purple  // Epic
        case 5: return .orange  // Legendary
        default: return .white
        }
    }

    /// Load recent items from UserDefaults
    private func loadRecentItems() {
        if let data = UserDefaults.standard.data(forKey: "RecentItems") {
            do {
                let items = try JSONDecoder().decode([ClassicItemPreview].self, from: data)
                recentItems = items
            } catch {
                print("Failed to load recent items: \(error)")
            }
        }
    }

    /// Add an item to recent items
    private func addToRecentItems(_ item: ClassicItemPreview) {
        // Check if item already exists
        if let existingIndex = recentItems.firstIndex(where: { $0.id == item.id }) {
            // Move to front
            recentItems.remove(at: existingIndex)
            recentItems.insert(item, at: 0)
        } else {
            // Add to front
            recentItems.insert(item, at: 0)

            // Limit to 10 items
            if recentItems.count > 10 {
                recentItems.removeLast()
            }
        }

        // Save to UserDefaults
        do {
            let data = try JSONEncoder().encode(recentItems)
            UserDefaults.standard.set(data, forKey: "RecentItems")
        } catch {
            print("Failed to save recent items: \(error)")
        }
    }

    /// Hide keyboard
    private func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Models

/// Search mode enum
enum SearchMode {
    case itemID
    case itemName
}

/// Classic item preview (basic info)
struct ClassicItemPreview: Identifiable, Codable {
    let id: Int
    let name: String
    let quality: Int
    let iconName: String
}

/// Classic item with detailed info
struct ClassicItem {
    let id: Int
    let name: String
    let quality: Int
    let iconName: String
    let itemType: String?
    let itemSubType: String?
    let bindType: String?
    let itemLevel: Int?
    let requiredLevel: Int
    let requiredClasses: String?
    let sellPrice: Int?
    let stats: [String]
    let itemSpells: [String]?
    let sources: [String]?
}

struct ItemLookupView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ItemLookupView()
        }
    }
}
