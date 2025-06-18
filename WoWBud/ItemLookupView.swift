//
//  ItemLookupView.swift
//  WoWBud
//
//  Created on 4/30/25.
//

import SwiftUI

// Platform-specific imports and typealiases
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    import AppKit
    typealias PlatformColor = NSColor
    typealias PlatformSharingPicker = NSSharingServicePicker
    typealias PlatformButton = NSButton
    typealias PlatformViewRepresentable = NSViewRepresentable
    let platformControlBackgroundColor = Color(PlatformColor.controlBackgroundColor)  // Use NSColor directly
    let platformApp = NSApp
#elseif canImport(UIKit)
    import UIKit
    typealias PlatformColor = UIColor
    let platformBackgroundColor = Color(UIColor.systemBackground)  // Main background
    let platformControlBackgroundColor = Color(UIColor.secondarySystemBackground)  // Control/Section background
    // No direct equivalent for NSSharingServicePicker, use UIActivityViewController
    // No direct equivalent for NSButton in this context
    // No direct equivalent for NSViewRepresentable in this context (use UIViewRepresentable)
    let platformApp = UIApplication.shared
#else
    #error("Unsupported platform")
#endif

// MARK: - Platform Agnostic Colors
extension Color {
    static var platformControlBackground: Color {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            return Color(PlatformColor.controlBackgroundColor)
        #elseif canImport(UIKit)
            return Color(UIColor.secondarySystemGroupedBackground)  // Suitable UIKit equivalent
        #else
            return Color.gray  // Fallback for unsupported platforms
        #endif
    }
}

struct ItemLookupView: View {
    // MARK: - State Variables
    @State private var searchText: String = ""
    @State private var searchMode: SearchMode = .itemID

    @State private var item: ClassicItem? = nil
    @State private var searchResults: [ClassicItemPreview] = []

    @State private var errorMessage: String? = nil
    @State private var isLoading: Bool = false
    @State private var recentItems: [ClassicItemPreview] = []

    // MARK: - Services
    private let apiService = ClassicAPIService()

    // MARK: - Platform Specific State (macOS)
    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        @State private var sharingServicePicker = PlatformSharingPicker(items: [])
        @State private var shareButton: PlatformButton?  // To anchor the picker
    #endif

    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            searchBar()  // Extracted search bar view

            // Main content area
            ScrollView {
                contentArea()  // Extracted content area view
            }
        }
        .navigationTitle("Classic Item Database")
        .onAppear(perform: loadRecentItems)  // Load recent items on appear
        .contentShape(Rectangle())  // Allow tapping outside text field to dismiss keyboard
        .onTapGesture(perform: hideKeyboard)
    }

    // MARK: - Subviews

    /// Builds the search bar view.
    @ViewBuilder
    private func searchBar() -> some View {
        HStack {
            // Search mode picker (ID/Name)
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
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                .background(Color(PlatformColor.controlBackgroundColor))  // Platform-specific background
            #elseif canImport(UIKit)
                .background(Color(PlatformColor.secondarySystemBackground))  // Use secondarySystemBackground for text field
            #endif
            .cornerRadius(8)
            #if canImport(UIKit)  // iOS specific keyboard type
                .keyboardType(searchMode == .itemID ? .numberPad : .default)
            #endif
            .onSubmit {  // Action on pressing Enter/Return
                hideKeyboard()
                Task { await performSearch() }
            }
            #if canImport(UIKit)  // iOS specific submit label
                .submitLabel(searchMode == .itemID ? .search : .done)
            #endif

            // Search button
            Button(action: {
                hideKeyboard()
                Task { await performSearch() }
            }) {
                Image(systemName: "magnifyingglass")
                    .padding(8)
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            .disabled(searchText.isEmpty || isLoading)  // Disable when loading or empty
        }
        .padding()
    }

    /// Builds the main content area based on the current state.
    @ViewBuilder
    private func contentArea() -> some View {
        // Loading indicator
        if isLoading {
            ProgressView("Loading...")
                .padding()
        }
        // Error message display
        else if let errorMessage = errorMessage {
            Text(errorMessage)
                .foregroundColor(.red)
                .padding()
        }
        // Detailed item view
        else if let item = item {
            itemDetailView(item)
        }
        // Search results list
        else if !searchResults.isEmpty {
            searchResultsList()  // Extracted search results list view
        }
        // Default view (recent items, tips)
        else {
            defaultContentView()
        }
    }

    /// Builds the default content view shown initially or when search is cleared.
    @ViewBuilder
    private func defaultContentView() -> some View {
        VStack(alignment: .leading, spacing: 24) {
            // Recently viewed items section
            if !recentItems.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Recently Viewed")
                        .font(.headline)
                        .padding(.horizontal)

                    // Display up to 5 recent items
                    ForEach(recentItems.prefix(5)) { itemPreview in
                        Button(action: {
                            Task { await loadItem(id: itemPreview.id) }
                        }) {
                            itemPreviewRow(itemPreview)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
            } else {
                // Placeholder text if no recent items
                Text("Search for an item or view recent items.")
                    .foregroundColor(.secondary)
                    .padding()
            }

            // Search tips section
            VStack(alignment: .leading, spacing: 8) {
                Text("Search Tips")
                    .font(.headline)
                Text("• Search by item ID for exact matches")
                Text("• Search by name for multiple results")
                Text("• Tap on items to view full details")
                // Text("• Phase 2 items available Dec 12") // Example placeholder
            }
            .padding()
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                .background(Color(PlatformColor.controlBackgroundColor))  // Platform-specific background
            #elseif canImport(UIKit)
                .background(Color(PlatformColor.secondarySystemBackground))  // Use secondarySystemBackground for tips section
            #endif
            .cornerRadius(10)
            .padding()
        }
        .padding(.top)
    }

    /// Builds the list of search results.
    @ViewBuilder
    private func searchResultsList() -> some View {
        LazyVStack(alignment: .leading, spacing: 16) {
            Text("Search Results")
                .font(.headline)
                .padding(.horizontal)

            // Iterate over search results and display preview rows
            ForEach(searchResults) { itemPreview in
                Button(action: {
                    Task { await loadItem(id: itemPreview.id) }
                }) {
                    itemPreviewRow(itemPreview)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
    }

    /// Builds a row view for an item preview (used in search results and recent items).
    /// - Parameter itemPreview: The `ClassicItemPreview` data to display.
    private func itemPreviewRow(_ itemPreview: ClassicItemPreview) -> some View {
        HStack(spacing: 12) {
            // Item icon with quality border
            itemPreviewIconView(itemPreview: itemPreview)

            // Item name and ID
            VStack(alignment: .leading, spacing: 4) {
                Text(itemPreview.name)
                    .font(.headline)
                    .foregroundColor(qualityColor(itemPreview.qualityType))  // Color based on quality

                Text("Item ID: \(itemPreview.id)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()  // Push chevron to the right

            // Navigation indicator
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            .background(Color(PlatformColor.controlBackgroundColor))  // Platform-specific background
        #elseif canImport(UIKit)
            .background(Color(PlatformColor.systemBackground))  // Use systemBackground for rows
        #endif
        .cornerRadius(8)
        .padding(.horizontal)  // Add horizontal padding around the row
    }

    /// Builds the item icon view with a quality-colored border for preview items.
    /// - Parameter itemPreview: The ClassicItemPreview containing icon information.
    private func itemPreviewIconView(itemPreview: ClassicItemPreview) -> some View {
        // Prefer the full API URL, fallback to constructing from filename
        let iconUrl: URL? = {
            if let iconURL = itemPreview.iconURL {
                return URL(string: iconURL)
            } else if let iconName = itemPreview.iconName {
                // Fallback to zamimg.com for older/missing icons
                return URL(string: "https://wow.zamimg.com/images/wow/icons/large/\(iconName).jpg")
            } else {
                return nil
            }
        }()

        return ZStack {
            // Quality border
            RoundedRectangle(cornerRadius: 6)
                .stroke(qualityColor(itemPreview.qualityType), lineWidth: 2)  // Color based on quality
                .background(Color.black.cornerRadius(6))  // Black background behind icon

            // Icon using AsyncImage for network loading
            if let url = iconUrl {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:  // While loading
                        ProgressView()
                            .frame(width: 20, height: 20)
                    case .success(let image):  // On successful load
                        image.resizable()
                            .aspectRatio(contentMode: .fit)
                    case .failure:  // On failure to load
                        Image(systemName: "questionmark.diamond.fill")
                            .foregroundColor(.gray)
                            .font(.caption)
                    @unknown default:  // Future cases
                        EmptyView()
                    }
                }
                .frame(maxWidth: 32, maxHeight: 32)  // Smaller for preview
                .cornerRadius(4)  // Slightly rounded corners for the icon itself
                .clipped()  // Clip icon to its bounds
            } else {
                // Fallback placeholder if no icon URL is available
                Image(systemName: "questionmark.diamond.fill")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
        }
        .frame(width: 40, height: 40) // Fixed size for preview icons
    }

    /// Builds the detailed view for a specific item.
    /// - Parameter item: The `ClassicItem` data to display.
    private func itemDetailView(_ item: ClassicItem) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Item Header: Icon, Name, Type, Binding, Item Level
            itemHeaderView(item)

            // Armor Section (if applicable)
            if let armor = item.armor, armor > 0 {
                detailSection {
                    Text("Armor").font(.headline)
                    Text("\(armor) Armor").font(.body)
                }
            }

            // Weapon Stats Section (if applicable)
            if let weaponInfo = item.weaponInfo {
                detailSection {
                    Text("Weapon").font(.headline)
                    HStack {
                        Text(weaponInfo.damageString)
                        Spacer()
                        Text(weaponInfo.speedString)
                    }
                    .font(.body)
                    Text(weaponInfo.dpsString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Stats Section (if applicable)
            if !item.stats.isEmpty {
                detailSection {
                    Text("Stats").font(.headline)
                    ForEach(item.stats, id: \.self) { stat in
                        Text(stat).font(.body)
                    }
                }
            }

            // Effects/Spells Section (if applicable)
            if let itemSpells = item.itemSpells, !itemSpells.isEmpty {
                detailSection {
                    Text("Effects").font(.headline)
                    ForEach(itemSpells, id: \.self) { spell in
                        Text(spell).font(.body).foregroundColor(.green)
                    }
                }
            }

            // Durability Section (if applicable)
            if let durability = item.durability, durability > 0 {
                detailSection {
                    // Use the pre-formatted display string if available, otherwise construct it
                    Text(item.durabilityDisplayString ?? "Durability \(durability) / \(durability)")
                        .font(.body)
                }
            }

            // Stack Size Section (if applicable)
            if let maxCount = item.maxCount, maxCount > 1 {
                detailSection {
                    Text("Stack Size: \(maxCount)").font(.body)
                }
            }

            // Sources Section (if applicable)
            if let sources = item.sources, !sources.isEmpty {
                detailSection {
                    Text("Sources").font(.headline)
                    ForEach(sources, id: \.self) { source in
                        HStack {
                            Image(systemName: "location").foregroundColor(.blue)
                            Text(source).font(.body)
                        }
                    }
                }
            }

            // Requirements Section (Level, Classes)
            let reqLevel = item.requiredLevel ?? 0
            if reqLevel > 0 || item.requiredClasses != nil {
                detailSection {
                    Text("Requirements").font(.headline)
                    if reqLevel > 0 {
                        Text("Required Level: \(reqLevel)").font(.body)
                    }
                    if let classes = item.requiredClasses {
                        Text("Classes: \(classes)").font(.body)
                    }
                }
            }

            // Flavor Text Section (if applicable)
            if let description = item.description, !description.isEmpty {
                detailSection {
                    Text("\"\(description)\"")  // Display in quotes
                        .font(.body)
                        .italic()
                        .foregroundColor(.yellow)  // Classic WoW flavor text color
                }
            }

            // Vendor Sell Price Section (if applicable)
            // Display if sellPrice has a value (even if 0, as some items have 0 sell price)
            if let sellPrice = item.sellPrice {
                detailSection {
                    HStack {
                        Text("Vendor Sell:").font(.headline)
                        Spacer()
                        // Use formatted strings if available, otherwise calculate from copper value
                        formatCurrency(sellPrice, formattedPrice: item.sellPriceDisplay)
                    }
                }
            }

            // Footer: Item ID, ClassicDB Link, Share Button
            itemFooterView(item)
        }
        .padding()  // Padding around the entire detail view content
    }

    /// Builds the header section of the item detail view.
    /// - Parameter item: The `ClassicItem` data.
    @ViewBuilder
    private func itemHeaderView(_ item: ClassicItem) -> some View {
        HStack(spacing: 16) {
            // Item icon
            itemIconView(item: item)
                .frame(width: 64, height: 64)

            // Item name, type, subtype, binding
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .foregroundColor(qualityColor(item.qualityType))  // Color based on quality

                // Display type and subtype if available
                if let itemType = item.itemType, let itemSubType = item.itemSubType {
                    Text("\(itemType) • \(itemSubType)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else if let itemType = item.itemType {  // Fallback to just type
                    Text(itemType)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Display Inventory Slot
                if let slot = item.inventorySlotName {
                    Text(slot)  // Added Inventory Slot
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Display binding type if available
                if let bindType = item.bindType {
                    Text(bindType)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Display Stack Count if > 1
                if let maxCount = item.maxCount, maxCount > 1 {
                    Text("Stack Size: \(maxCount)")  // Added Stack Size
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Display Equippable/Stackable flags
                HStack(spacing: 8) {
                    if item.isEquippable == true {
                        Text("Equippable")
                            .font(.caption2)
                            .padding(.horizontal, 4)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(4)
                    }
                    if item.isStackable == true {
                        Text("Stackable")
                            .font(.caption2)
                            .padding(.horizontal, 4)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
                .padding(.top, 2)

            }

            Spacer()  // Push item level badge to the right

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
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            .background(Color(PlatformColor.controlBackgroundColor))  // Platform-specific background
        #elseif canImport(UIKit)
            .background(Color(PlatformColor.secondarySystemBackground))  // Use secondarySystemBackground for header section
        #endif
        .cornerRadius(10)
    }

    /// Builds the footer section of the item detail view (ID, Link, Share).
    /// - Parameter item: The `ClassicItem` data.
    @ViewBuilder
    private func itemFooterView(_ item: ClassicItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {  // Use VStack for multiple lines
            // Stack Size
            if let maxCount = item.maxCount, maxCount > 1 {
                Text("Stack Size: \(maxCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                // Display Item ID
                Text("Item ID:").font(.caption).foregroundColor(.secondary)
                Text("\(item.id)").font(.caption).foregroundColor(.secondary)

                Spacer()  // Push link and share button to the right

                // Link to ClassicDB
                if let url = URL(string: "https://classicdb.ch/?item=\(item.id)") {
                    SwiftUI.Link(destination: url) {
                        Image(systemName: "link").foregroundColor(.blue)
                    }
                    .padding(.trailing, 8)  // Spacing before share button
                }

                // Platform-specific Share button
                #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                    // macOS Share button using NSSharingServicePicker
                    Button(action: { showShareSheet(item: item) }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .buttonStyle(.plain)  // Just show the image
                    .foregroundColor(.blue)
                    .background(  // Helper to get the underlying NSButton for anchoring
                        RepresentedPlatformButton { nsButton in
                            DispatchQueue.main.async { self.shareButton = nsButton }
                        }
                    )
                #elseif canImport(UIKit)
                    // iOS Share button using UIActivityViewController
                    Button(action: { showShareSheet(item: item) }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .foregroundColor(.blue)
                #endif
            }
        }
        .padding()  // Padding around the footer content
    }

    /// Helper to create consistently styled sections in the detail view.
    /// - Parameter content: The content view builder for the section.
    @ViewBuilder
    private func detailSection<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            content()  // Embed the provided content
        }
        .padding()  // Padding inside the section
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            .background(Color(PlatformColor.controlBackgroundColor))  // Platform-specific background
        #elseif canImport(UIKit)
            .background(Color(PlatformColor.secondarySystemBackground))  // Use secondarySystemBackground for detail sections
        #endif
        .cornerRadius(10)  // Rounded corners for the section
    }

    /// Helper to format currency (copper) into gold, silver, copper strings.
    /// - Parameter price: The price in copper.
    /// - Parameter formattedPrice: Optional pre-formatted price strings from API.
    @ViewBuilder
    private func formatCurrency(_ price: Int, formattedPrice: ClassicItem.FormattedPrice? = nil)
        -> some View
    {
        // Prefer using pre-formatted strings if available
        if let display = formattedPrice,
            display.gold != nil || display.silver != nil || display.copper != nil
        {
            HStack(spacing: 4) {
                if let gold = display.gold { Text(gold).foregroundColor(.yellow) }
                if let silver = display.silver { Text(silver).foregroundColor(.gray) }
                if let copper = display.copper { Text(copper).foregroundColor(.orange) }
            }
            .font(.body)
        } else {
            // Fallback to calculating from copper value
            let gold = price / 10000
            let silver = (price % 10000) / 100
            let copper = price % 100

            HStack(spacing: 4) {
                if gold > 0 { Text("\(gold)g").foregroundColor(.yellow) }
                if silver > 0 { Text("\(silver)s").foregroundColor(.gray) }
                if copper > 0 { Text("\(copper)c").foregroundColor(.orange) }
                // Show 0c if price is 0 and no other units are shown
                if gold == 0 && silver == 0 && copper == 0 && price == 0 {
                    Text("0c").foregroundColor(.orange)
                }
            }
            .font(.body)
        }
    }

    // Helper struct to access the underlying NSButton from SwiftUI Button (macOS only)
    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        struct RepresentedPlatformButton: PlatformViewRepresentable {
            var configuration: (PlatformButton) -> Void

            // Creates the NSButton instance
            func makeNSView(context: Context) -> PlatformButton {
                let button = PlatformButton()
                configuration(button)  // Apply configuration (capture reference)
                return button
            }

            // Updates the NSButton (not needed here)
            func updateNSView(_ nsView: PlatformButton, context: Context) {}
        }
    #endif

    /// Builds the item icon view with a quality-colored border.
    /// - Parameters:
    ///   - item: The ClassicItem containing icon information.
    ///   - qualityType: The quality type string (e.g., "EPIC").
    private func itemIconView(item: ClassicItem) -> some View {
        // Prefer the full API URL, fallback to constructing from filename
        let iconUrl: URL? = {
            if let iconURL = item.iconURL {
                return URL(string: iconURL)
            } else if let iconName = item.iconName {
                // Fallback to zamimg.com for older/missing icons
                return URL(string: "https://wow.zamimg.com/images/wow/icons/large/\(iconName).jpg")
            } else {
                return nil
            }
        }()

        return ZStack {
            // Quality border
            RoundedRectangle(cornerRadius: 6)
                .stroke(qualityColor(item.qualityType), lineWidth: 2)  // Color based on quality
                .background(Color.black.cornerRadius(6))  // Black background behind icon

            // Icon using AsyncImage for network loading
            if let url = iconUrl {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:  // While loading
                        ProgressView()
                            .frame(width: 30, height: 30)
                    case .success(let image):  // On successful load
                        image.resizable()
                            .aspectRatio(contentMode: .fit)
                    case .failure:  // On failure to load
                        Image(systemName: "questionmark.diamond.fill")
                            .foregroundColor(.gray)
                            .font(.title2)
                    @unknown default:  // Future cases
                        EmptyView()
                    }
                }
                .frame(maxWidth: 50, maxHeight: 50)  // Constrain image size
                .cornerRadius(4)  // Slightly rounded corners for the icon itself
                .clipped()  // Clip icon to its bounds
            } else {
                // Fallback placeholder if no icon URL is available
                Image(systemName: "questionmark.diamond.fill")
                    .foregroundColor(.gray)
                    .font(.title2)
            }
        }
    }

    // MARK: - Functionality

    /// Performs the search based on the current mode (ID or Name).
    @MainActor
    private func performSearch() async {
        guard !searchText.isEmpty else { return }  // Exit if search text is empty

        // Reset state for new search
        isLoading = true
        errorMessage = nil
        searchResults = []
        item = nil

        do {
            if searchMode == .itemID {
                // Validate and perform ID search
                guard let itemID = Int(searchText) else {
                    errorMessage = "Please enter a valid item ID"
                    isLoading = false
                    return
                }
                await loadItem(id: itemID)  // loadItem handles its own loading state
            } else {
                // Perform name search
                let searchResponse = try await apiService.searchItems(name: searchText)

                // Map API results to preview model
                searchResults = searchResponse.results.compactMap { result -> ClassicItemPreview? in
                    // Extract icon information from the search result data
                    let iconURL = result.data.getIconURL()
                    let iconName = result.data.media?.getIconName()
                    
                    return ClassicItemPreview(
                        id: result.data.id,
                        name: result.data.name,
                        qualityType: result.data.quality.type,
                        iconName: iconName,
                        iconURL: iconURL
                    )
                }

                // Set error message if no results found
                if searchResults.isEmpty {
                    errorMessage = "No items found matching '\(searchText)'"
                }
                isLoading = false  // Stop loading after name search completes
            }
        } catch let error as AppError {
            errorMessage = "Search failed: \(error.localizedDescription)"
            print("API Error during search: \(error)")
            isLoading = false  // Ensure loading stops on error
        } catch {
            errorMessage =
                "An unexpected error occurred during search: \(error.localizedDescription)"
            print("Unexpected error during search: \(error)")
            isLoading = false  // Ensure loading stops on error
        }
    }

    /// Loads detailed information for a specific item ID.
    /// - Parameter id: The ID of the item to load.
    @MainActor
    private func loadItem(id: Int) async {
        // Set loading state (even if called from performSearch)
        isLoading = true
        errorMessage = nil
        searchResults = []  // Clear search results when loading a specific item
        item = nil
        var fetchedIconName: String? = nil
        var fetchedIconURL: String? = nil
        var weaponDetails: ClassicItem.WeaponInfo? = nil

        do {
            // Fetch main item data from API
            let apiItem = try await apiService.item(id: id)

            // Fetch media data (for icon) concurrently or subsequently
            let mediaResponse = try? await apiService.fetchItemMedia(id: id)
            
            // Try to get the full icon URL from the API first (Anniversary Edition icons)
            fetchedIconURL = mediaResponse?.assets?.first(where: { $0.key == "icon" })?.value
                ?? apiItem.getIconURL() // Fallback to item's own media
            
            // Also get the icon name as fallback
            fetchedIconName = mediaResponse?.getIconName()  // Extract icon name

            // Extract weapon info if available using helper functions
            if apiItem.previewItem?.weapon != nil {
                weaponDetails = ClassicItem.WeaponInfo(
                    damageString: apiItem.getWeaponDamageString() ?? "",
                    speedString: apiItem.getWeaponAttackSpeedString() ?? "",
                    dpsString: apiItem.getWeaponDpsString() ?? ""
                )
            }

            // Map fetched API data to the local ClassicItem model
            let fetchedItem = ClassicItem(
                id: apiItem.id,
                name: apiItem.name,
                qualityType: apiItem.getQualityType(),
                iconName: fetchedIconName,
                iconURL: fetchedIconURL,
                itemType: apiItem.itemClass.name,
                itemSubType: apiItem.itemSubclass.name,
                inventorySlotName: apiItem.inventoryType.name,  // Ensure inventorySlotName is mapped
                inventoryTypeName: apiItem.inventoryType.name,  // Map inventory type name
                bindType: apiItem.getBindingString(),
                itemLevel: apiItem.getItemLevel(),
                requiredLevel: apiItem.requiredLevel,
                requiredClasses: apiItem.getRequiredClassesString(),
                sellPrice: apiItem.getSellPriceCopper(),  // Use helper for copper value
                sellPriceDisplay: mapFormattedPrice(apiItem.previewItem?.sellPrice?.displayStrings),  // Map formatted sell price
                maxCount: apiItem.maxCount,  // Added max stack count
                isEquippable: apiItem.isEquippable,  // Added equippable flag
                isStackable: apiItem.isStackable,  // Added stackable flag
                stats: apiItem.getFormattedStats(),
                itemSpells: apiItem.getFormattedSpells(),
                sources: nil,  // Source info not directly available from this endpoint
                armor: apiItem.previewItem?.armor?.value,
                durability: apiItem.getDurabilityValue(),  // Use helper
                description: apiItem.previewItem?.description,
                weaponInfo: weaponDetails,
                durabilityDisplayString: apiItem.previewItem?.durability?.displayString
            )

            // Update the view's state
            self.item = fetchedItem

            // Add to recent items list
            let preview = ClassicItemPreview(
                id: fetchedItem.id,
                name: fetchedItem.name,
                qualityType: fetchedItem.qualityType,
                iconName: fetchedItem.iconName,
                iconURL: fetchedItem.iconURL
            )
            self.addToRecentItems(preview)

        } catch let error as AppError {
            // Handle specific API errors (e.g., 404 Not Found)
            if case .badStatus(let code) = error, code == 404 {
                errorMessage = "Item with ID \(id) not found."
            } else {
                errorMessage = "Failed to load item \(id): \(error.localizedDescription)"
            }
            print("API Error loading item \(id): \(error)")
        } catch {
            // Handle unexpected errors
            errorMessage =
                "An unexpected error occurred loading item \(id): \(error.localizedDescription)"
            print("Unexpected error loading item \(id): \(error)")
        }

        // Ensure loading indicator is turned off
        isLoading = false
    }

    /// Returns the appropriate color for a given item quality type string.
    /// - Parameter qualityType: The quality type (e.g., "EPIC", "RARE").
    private func qualityColor(_ qualityType: String) -> Color {
        switch qualityType.uppercased() {
        case "POOR": return .gray
        case "COMMON": return .white
        case "UNCOMMON": return .green
        case "RARE": return .blue
        case "EPIC": return .purple
        case "LEGENDARY": return .orange
        case "ARTIFACT": return .yellow  // May not apply to Classic Era
        default: return .white  // Default to common
        }
    }

    /// Loads the list of recently viewed items from UserDefaults.
    private func loadRecentItems() {
        guard let data = UserDefaults.standard.data(forKey: "RecentItems") else {
            recentItems = []  // No saved data
            return
        }
        do {
            // Decode the saved data
            recentItems = try JSONDecoder().decode([ClassicItemPreview].self, from: data)
        } catch {
            // Handle decoding errors (e.g., data format changed)
            print("Failed to decode recent items: \(error). Clearing potentially corrupted data.")
            UserDefaults.standard.removeObject(forKey: "RecentItems")  // Clear corrupted data
            recentItems = []
        }
    }

    /// Adds an item to the recent items list and saves to UserDefaults.
    /// - Parameter item: The `ClassicItemPreview` to add.
    private func addToRecentItems(_ item: ClassicItemPreview) {
        // Remove item if it already exists to move it to the front
        recentItems.removeAll { $0.id == item.id }
        // Insert at the beginning
        recentItems.insert(item, at: 0)
        // Limit the list size (e.g., to 10 items)
        if recentItems.count > 10 {
            recentItems.removeLast()
        }
        // Save the updated list to UserDefaults
        do {
            let data = try JSONEncoder().encode(recentItems)
            UserDefaults.standard.set(data, forKey: "RecentItems")
        } catch {
            print("Failed to save recent items: \(error)")
        }
    }

    /// Shows the platform-specific share sheet for the given item.
    /// - Parameter item: The `ClassicItem` to share.
    private func showShareSheet(item: ClassicItem) {
        let shareText =
            "Check out this Classic WoW item: \(item.name) (ID: \(item.id)) - via WoWBud"

        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            // macOS: Use NSSharingServicePicker anchored to the button
            sharingServicePicker = PlatformSharingPicker(items: [shareText])
            if let button = shareButton {
                sharingServicePicker.show(relativeTo: .zero, of: button, preferredEdge: .minY)
            } else {
                print("Warning: Share button reference not available for anchoring picker.")
                // Consider a fallback presentation method if needed
            }
        #elseif canImport(UIKit)
            // iOS: Use UIActivityViewController
            guard let sourceView = findSourceView() else {
                print("Warning: Could not find source view for iOS share sheet.")
                return
            }
            let activityViewController = UIActivityViewController(
                activityItems: [shareText], applicationActivities: nil)

            // Configure popover for iPad
            if let popoverController = activityViewController.popoverPresentationController {
                popoverController.sourceView = sourceView
                popoverController.sourceRect = sourceView.bounds  // Adjust rect as needed
            }

            // Present the share sheet
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                let rootViewController = windowScene.windows.first?.rootViewController
            else { return }
            rootViewController.present(activityViewController, animated: true, completion: nil)
        #endif
    }

    #if canImport(UIKit)
        /// Helper function to find a source UIView for the share sheet on iOS.
        /// Needs refinement for specific button anchoring.
        private func findSourceView() -> UIView? {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                let window = windowScene.windows.first
            else { return nil }
            // Use the root view controller's view as a fallback source
            return window.rootViewController?.view ?? window
        }
    #endif

    /// Hides the keyboard in a platform-agnostic way.
    private func hideKeyboard() {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            // macOS: Resign first responder status for the key window
            DispatchQueue.main.async {
                platformApp.keyWindow?.makeFirstResponder(nil)
            }
        #elseif canImport(UIKit)
            // iOS: Send resignFirstResponder action globally
            platformApp.sendAction(
                #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }

    /// Helper function to map API's DisplayStrings to ClassicItem.FormattedPrice
    private func mapFormattedPrice(_ displayStrings: PreviewItem.SellPrice.DisplayStrings?)
        -> ClassicItem.FormattedPrice?
    {
        guard let display = displayStrings else { return nil }
        return ClassicItem.FormattedPrice(
            gold: display.gold,
            silver: display.silver,
            copper: display.copper
        )
    }

    /// Helper function to build the type/subtype/inventory string
    private func buildTypeString(item: ClassicItem) -> String {
        var components: [String] = []
        if let type = item.inventoryTypeName { components.append(type) }  // Prefer inventory slot name
        if let subType = item.itemSubType { components.append(subType) }
        // Add itemType (Armor/Weapon) only if inventoryTypeName is missing or different from itemType
        if let itemType = item.itemType,
            item.inventoryTypeName == nil || item.inventoryTypeName != itemType
        {
            if !components.contains(itemType) {  // Avoid duplicates like "Plate • Plate"
                components.append(itemType)
            }
        }
        return components.joined(separator: " • ")
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
    let qualityType: String  // Store quality type string (e.g., "EPIC")
    let iconName: String?  // Store icon filename (optional)
    let iconURL: String?   // Store full icon URL (optional)
}

/// Classic item with detailed info
struct ClassicItem {  // This struct is local to the View
    let id: Int
    let name: String
    let qualityType: String  // e.g., "EPIC"
    let iconName: String?  // Just the filename, e.g., "inv_sword_43"
    let iconURL: String?   // Full URL to the icon from API
    let itemType: String?  // From ItemClass.name (e.g., "Armor")
    let itemSubType: String?  // From ItemSubclass.name (e.g., "Cloth")
    let inventorySlotName: String?  // e.g., "Chest", "Trinket"
    let inventoryTypeName: String?  // From InventoryType.name (e.g., "Chest")
    let bindType: String?  // e.g., "Binds when picked up"
    let itemLevel: Int?
    let requiredLevel: Int?  // Changed to optional to handle API variability
    let requiredClasses: String?  // e.g., "Warrior, Paladin" - needs mapping if API gives IDs
    let sellPrice: Int?  // Sell price in copper
    let sellPriceDisplay: FormattedPrice?  // Formatted g/s/c strings from API
    let maxCount: Int?  // Max stack size
    let isEquippable: Bool?
    let isStackable: Bool?
    let stats: [String]  // Pre-formatted stat strings (simplest approach)
    // Or: let stats: [ItemStat] if you want structured data here
    let itemSpells: [String]?  // Pre-formatted spell descriptions
    let sources: [String]?  // Pre-formatted source descriptions
    // --- New Fields ---
    let armor: Int?  // Armor value
    let durability: Int?  // Durability value
    let description: String?  // Flavor text
    let weaponInfo: WeaponInfo?  // Weapon specific stats
    let durabilityDisplayString: String?  // Add field for pre-formatted durability string

    // Nested struct for weapon details
    struct WeaponInfo: Hashable {  // Conforms to Hashable if needed
        let damageString: String  // e.g., "37 - 69 Damage"
        let speedString: String  // e.g., "Speed 1.50"
        let dpsString: String  // e.g., "(35.3 damage per second)"
    }

    // Nested struct for formatted price strings
    struct FormattedPrice: Hashable {
        let gold: String?
        let silver: String?
        let copper: String?
    }
}

struct ItemLookupView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ItemLookupView()
        }
    }
}