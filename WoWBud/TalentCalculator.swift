//
//  TalentCalculatorView.swift
//  WoWBud
//
//  Created on 4/30/25.
//

import SwiftUI

/// View for WoW Classic talent calculator
struct TalentCalculatorView: View {
    // Currently selected class
    @State private var selectedClassID: Int = 1  // Warrior by default

    // Selected specialization tab (0, 1, 2)
    @State private var selectedSpecTab: Int = 0

    // Currently selected talent points for each spec
    @State private var selectedTalents: [Int: [Int: Int]] = [:]  // [specIndex: [talentID: points]]

    // Character level
    @State private var characterLevel: Int = 60

    // Available talent points
    @State private var availablePoints: Int = 51

    // Classes data
    @State private var classes: [ClassData] = []

    // Loading state
    @State private var isLoading: Bool = false

    // Error message
    @State private var errorMessage: String? = nil

    // Saved builds state
    @State private var showingSavedBuilds: Bool = false
    @State private var buildName: String = ""
    @State private var savedBuilds: [TalentBuild] = []

    var body: some View {
        VStack(spacing: 0) {
            // Header with class selector and points counter
            VStack(spacing: 8) {
                // Class selector
                if !classes.isEmpty {
                    Picker("Class", selection: $selectedClassID) {
                        ForEach(classes) { wowClass in
                            Text(wowClass.name).tag(wowClass.id)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: selectedClassID) { oldValue, newValue in
                        resetTalents()
                    }
                }

                // Points counter and level
                HStack {
                    Text("Level: \(characterLevel)")
                        .font(.subheadline)

                    Spacer()

                    Text("Points: \(availablePoints)/\(totalPointsForLevel(characterLevel))")
                        .font(.subheadline)

                    Spacer()

                    Button("Reset") {
                        resetTalents()
                    }
                    .font(.subheadline)
                    .disabled(spentPoints == 0)
                }
                .padding(.horizontal)

                // Level slider
                Slider(
                    value: Binding(
                        get: { Double(characterLevel) },
                        set: { self.characterLevel = max(10, min(60, Int($0))) }
                    ), in: 10...60, step: 1
                )
                .padding(.horizontal)
                .onChange(of: characterLevel) { oldValue, newValue in
                    updateAvailablePoints()
                }
            }
            .padding(.top)

            // Spec tabs
            specTabsView

            // Main content area
            if isLoading {
                Spacer()
                ProgressView("Loading talents...")
                Spacer()
            } else if let errorMessage = errorMessage {
                Spacer()
                Text(errorMessage)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()
                Spacer()
            } else {
                // Talent tree view
                ScrollView {
                    talentTreeView
                }
                .background(Color(.systemBackground))
            }

            // Bottom toolbar
            HStack {
                Button(action: {
                    showingSavedBuilds = true
                }) {
                    Label("Builds", systemImage: "folder")
                }

                Spacer()

                // Share button
                Button(action: {
                    shareBuild()
                }) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }

                Spacer()

                // Info button
                Button(action: {
                    // Show info about build
                    showBuildInfo()
                }) {
                    Label("Info", systemImage: "info.circle")
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
        }
        .sheet(isPresented: $showingSavedBuilds) {
            savedBuildsView
        }
        .navigationTitle("Classic Talent Calculator")
        .onAppear {
            loadClassData()
        }
    }

    // MARK: - Subviews

    /// View for spec tabs
    private var specTabsView: some View {
        let currentClass = classes.first { $0.id == selectedClassID }

        return HStack(spacing: 0) {
            ForEach(0..<3) { index in
                let specName = currentClass?.specs[safe: index]?.name ?? "Specialization \(index+1)"
                let isSelected = selectedSpecTab == index

                Button(action: {
                    selectedSpecTab = index
                }) {
                    VStack(spacing: 4) {
                        Text(specName)
                            .font(.subheadline)
                            .fontWeight(isSelected ? .semibold : .regular)

                        // Show spent points in this tree
                        if let specTalents = selectedTalents[index], !specTalents.isEmpty {
                            let spent = specTalents.values.reduce(0, +)
                            Text("\(spent)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(isSelected ? Color(.secondarySystemBackground) : Color.clear)
                }
            }
        }
        .background(Color(.tertiarySystemBackground))
    }

    /// View for talent tree content
    private var talentTreeView: some View {
        let currentClass = classes.first { $0.id == selectedClassID }
        let currentSpec = currentClass?.specs[safe: selectedSpecTab]

        return VStack(spacing: 20) {
            if let spec = currentSpec {
                // Group nodes by tier (row)
                ForEach(0..<6) { tier in
                    HStack(spacing: 8) {
                        // Display talents in this tier
                        ForEach(0..<4) { column in
                            // Find talent at this position
                            if let talent = spec.talents.first(where: {
                                $0.tier == tier && $0.column == column
                            }) {
                                talentNodeView(talent: talent, specIndex: selectedSpecTab)
                            } else {
                                // Empty slot
                                Rectangle()
                                    .opacity(0)
                                    .frame(width: 52, height: 52)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            } else {
                Text("No talent data available")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .padding(.vertical)
    }

    /// View for a single talent node
    private func talentNodeView(talent: ClassData.Talent, specIndex: Int) -> some View {
        // Get currently spent points in this talent
        let currentPoints = selectedTalents[specIndex]?[talent.id] ?? 0

        return VStack(spacing: 4) {
            // Talent icon
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        talentBackgroundColor(
                            talent: talent, currentPoints: currentPoints, specIndex: specIndex)
                    )
                    .frame(width: 52, height: 52)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.black.opacity(0.5), lineWidth: 1)
                    )

                // Mock icon (in a real app, would be loaded from assets or API)
                Image(systemName: getIconName(for: talent))
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }

            // Rank indicator
            if currentPoints > 0 || canLearnTalent(talent: talent, specIndex: specIndex) {
                Text("\(currentPoints)/\(talent.ranks)")
                    .font(.caption2)
                    .foregroundColor(currentPoints > 0 ? .primary : .secondary)
            }
        }
        .onTapGesture {
            // Try to add a point
            learnTalent(talent: talent, specIndex: specIndex)
        }
        .onLongPressGesture {
            // Remove a point
            unlearnTalent(talent: talent, specIndex: specIndex)
        }
        .contentShape(Rectangle())  // Make entire area tappable
    }

    /// View for saved builds sheet
    private var savedBuildsView: some View {
        NavigationView {
            VStack {
                // List of saved builds
                if savedBuilds.isEmpty {
                    Spacer()
                    Text("No saved builds")
                        .foregroundColor(.secondary)
                    Spacer()
                } else {
                    List {
                        ForEach(savedBuilds) { build in
                            Button(action: {
                                // Load this build
                                loadBuild(build)
                                showingSavedBuilds = false
                            }) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(build.name)
                                        .font(.headline)

                                    Text(
                                        "\(build.className) (\(build.points[0])/\(build.points[1])/\(build.points[2]))"
                                    )
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .onDelete { indexSet in
                            savedBuilds.remove(atOffsets: indexSet)
                            // In a real app, would save to persistent storage
                        }
                    }
                }

                // Save current build form
                VStack(spacing: 12) {
                    TextField("Build Name", text: $buildName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    Button("Save Current Build") {
                        saveBuild()
                    }
                    .disabled(buildName.isEmpty || spentPoints == 0)
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
            }
            .navigationTitle("Saved Builds")
            .navigationBarItems(
                trailing: Button("Done") {
                    showingSavedBuilds = false
                })
        }
    }

    // MARK: - Functionality

    /// Load class data (in a real app, this would be from API)
    private func loadClassData() {
        isLoading = true
        errorMessage = nil

        // In a real app, this would fetch from API or local JSON
        // For now, let's use mock data
        classes = [
            ClassData(
                id: 1,
                name: "Warrior",
                powerType: "Rage",
                specs: [
                    ClassData.Spec(name: "Arms", talents: createTalents(specIndex: 0, classID: 1)),
                    ClassData.Spec(name: "Fury", talents: createTalents(specIndex: 1, classID: 1)),
                    ClassData.Spec(
                        name: "Protection", talents: createTalents(specIndex: 2, classID: 1)),
                ]
            ),
            ClassData(
                id: 2,
                name: "Paladin",
                powerType: "Mana",
                specs: [
                    ClassData.Spec(name: "Holy", talents: createTalents(specIndex: 0, classID: 2)),
                    ClassData.Spec(
                        name: "Protection", talents: createTalents(specIndex: 1, classID: 2)),
                    ClassData.Spec(
                        name: "Retribution", talents: createTalents(specIndex: 2, classID: 2)),
                ]
            ),
            ClassData(
                id: 3,
                name: "Hunter",
                powerType: "Mana",
                specs: [
                    ClassData.Spec(
                        name: "Beast Mastery", talents: createTalents(specIndex: 0, classID: 3)),
                    ClassData.Spec(
                        name: "Marksmanship", talents: createTalents(specIndex: 1, classID: 3)),
                    ClassData.Spec(
                        name: "Survival", talents: createTalents(specIndex: 2, classID: 3)),
                ]
            ),
            ClassData(
                id: 4,
                name: "Rogue",
                powerType: "Energy",
                specs: [
                    ClassData.Spec(
                        name: "Assassination", talents: createTalents(specIndex: 0, classID: 4)),
                    ClassData.Spec(
                        name: "Combat", talents: createTalents(specIndex: 1, classID: 4)),
                    ClassData.Spec(
                        name: "Subtlety", talents: createTalents(specIndex: 2, classID: 4)),
                ]
            ),
            ClassData(
                id: 5,
                name: "Priest",
                powerType: "Mana",
                specs: [
                    ClassData.Spec(
                        name: "Discipline", talents: createTalents(specIndex: 0, classID: 5)),
                    ClassData.Spec(name: "Holy", talents: createTalents(specIndex: 1, classID: 5)),
                    ClassData.Spec(
                        name: "Shadow", talents: createTalents(specIndex: 2, classID: 5)),
                ]
            ),
            ClassData(
                id: 7,
                name: "Shaman",
                powerType: "Mana",
                specs: [
                    ClassData.Spec(
                        name: "Elemental", talents: createTalents(specIndex: 0, classID: 7)),
                    ClassData.Spec(
                        name: "Enhancement", talents: createTalents(specIndex: 1, classID: 7)),
                    ClassData.Spec(
                        name: "Restoration", talents: createTalents(specIndex: 2, classID: 7)),
                ]
            ),
            ClassData(
                id: 8,
                name: "Mage",
                powerType: "Mana",
                specs: [
                    ClassData.Spec(
                        name: "Arcane", talents: createTalents(specIndex: 0, classID: 8)),
                    ClassData.Spec(name: "Fire", talents: createTalents(specIndex: 1, classID: 8)),
                    ClassData.Spec(name: "Frost", talents: createTalents(specIndex: 2, classID: 8)),
                ]
            ),
            ClassData(
                id: 9,
                name: "Warlock",
                powerType: "Mana",
                specs: [
                    ClassData.Spec(
                        name: "Affliction", talents: createTalents(specIndex: 0, classID: 9)),
                    ClassData.Spec(
                        name: "Demonology", talents: createTalents(specIndex: 1, classID: 9)),
                    ClassData.Spec(
                        name: "Destruction", talents: createTalents(specIndex: 2, classID: 9)),
                ]
            ),
            ClassData(
                id: 11,
                name: "Druid",
                powerType: "Mana",
                specs: [
                    ClassData.Spec(
                        name: "Balance", talents: createTalents(specIndex: 0, classID: 11)),
                    ClassData.Spec(
                        name: "Feral Combat", talents: createTalents(specIndex: 1, classID: 11)),
                    ClassData.Spec(
                        name: "Restoration", talents: createTalents(specIndex: 2, classID: 11)),
                ]
            ),
        ]

        // Initialize talents structure
        selectedTalents = [0: [:], 1: [:], 2: [:]]

        // Update available points
        updateAvailablePoints()

        isLoading = false
    }

    /// Create talents for a given spec (mock data)
    private func createTalents(specIndex: Int, classID: Int) -> [ClassData.Talent] {
        var talents: [ClassData.Talent] = []

        // Create a grid of talents (6 tiers x 4 columns max)
        for tier in 0..<6 {
            // Not all slots have talents
            let columnsInThisTier = min(4, tier == 0 ? 3 : (tier == 5 ? 1 : 4))

            for column in 0..<columnsInThisTier {
                // Skip some positions to create a more realistic tree shape
                if tier > 0 && tier < 5 && [0, 3].contains(column) && Bool.random() {
                    continue
                }

                // Only one talent in tier 5 (final tier)
                if tier == 5 && column != 1 {
                    continue
                }

                // Generate a unique ID for this talent
                let talentID = (classID * 1000) + (specIndex * 100) + (tier * 10) + column

                // Random number of ranks (1-5)
                let ranks = tier == 5 ? 1 : (1 + Int.random(in: 0..<5))

                // Generate a random prerequisite for some talents in higher tiers
                var prerequisiteID: Int? = nil
                if tier >= 2 && Bool.random() {
                    // Pick a talent from the tier above
                    let prereqTier = tier - 1
                    let prereqColumn = min(column, 2)  // Ensure it exists
                    prerequisiteID =
                        (classID * 1000) + (specIndex * 100) + (prereqTier * 10) + prereqColumn
                }

                // Create the talent
                let talent = ClassData.Talent(
                    id: talentID,
                    name: "Talent \(talentID)",
                    tier: tier,
                    column: column,
                    ranks: ranks,
                    prerequisiteID: prerequisiteID
                )

                talents.append(talent)
            }
        }

        return talents
    }

    /// Check if a talent can be learned
    private func canLearnTalent(talent: ClassData.Talent, specIndex: Int) -> Bool {
        // Check if we have points available
        guard availablePoints > 0 else { return false }

        // Check if we've maxed out this talent
        let currentPoints = selectedTalents[specIndex]?[talent.id] ?? 0
        guard currentPoints < talent.ranks else { return false }

        // Check if we've put enough points in this tier
        let requiredPoints = talent.tier * 5

        // Calculate how many points we've spent in this tree
        let spentPointsInTree = selectedTalents[specIndex]?.values.reduce(0, +) ?? 0

        // Check prerequisite if applicable
        if let prereqID = talent.prerequisiteID {
            let prereqPoints = selectedTalents[specIndex]?[prereqID] ?? 0
            let prereqTalent = classes.first { $0.id == selectedClassID }?
                .specs[specIndex].talents.first { $0.id == prereqID }

            if let prereq = prereqTalent, prereqPoints < prereq.ranks {
                return false
            }
        }

        return spentPointsInTree >= requiredPoints
    }

    /// Check if a talent can be unlearned
    private func canUnlearnTalent(talent: ClassData.Talent, specIndex: Int) -> Bool {
        // Check if we have any points in this talent
        guard let currentPoints = selectedTalents[specIndex]?[talent.id], currentPoints > 0 else {
            return false
        }

        // Get class and spec data
        guard let currentClass = classes.first(where: { $0.id == selectedClassID }),
            let spec = currentClass.specs[safe: specIndex]
        else { return false }

        // Check if any talent depends on this one
        for otherTalent in spec.talents {
            if otherTalent.prerequisiteID == talent.id {
                let otherPoints = selectedTalents[specIndex]?[otherTalent.id] ?? 0
                if otherPoints > 0 {
                    return false  // Can't unlearn if a dependent talent has points
                }
            }
        }

        // Check if removing this point would break tier requirements
        // Get all spent talent points sorted by tier
        var talentsByTier: [Int: [Int]] = [:]

        // Group talent IDs by their tier
        if let specTalents = selectedTalents[specIndex] {
            for talentID in specTalents.keys {
                if let talent = spec.talents.first(where: { $0.id == talentID }) {
                    let tier = talent.tier
                    if talentsByTier[tier] == nil {
                        talentsByTier[tier] = []
                    }
                    talentsByTier[tier]?.append(talentID)
                }
            }
        }

        // If this is the highest tier with points, we can always remove
        let pointTier = talent.tier
        let highestTier = talentsByTier.keys.max() ?? 0

        if pointTier < highestTier {
            // If it's a lower tier, check if removing would break requirements
            // Removing this point would reduce total in tree
            let newTotal = (selectedTalents[specIndex]?.values.reduce(0, +) ?? 0) - 1

            // Check if any higher tier would now have insufficient points
            for tier in (pointTier + 1)...highestTier {
                let requiredPoints = tier * 5
                if newTotal < requiredPoints {
                    return false  // This would break tier requirements
                }
            }
        }

        return true
    }

    /// Learn a talent (add a point)
    private func learnTalent(talent: ClassData.Talent, specIndex: Int) {
        guard canLearnTalent(talent: talent, specIndex: specIndex) else { return }

        // Initialize the spec's talent dictionary if it doesn't exist
        if selectedTalents[specIndex] == nil {
            selectedTalents[specIndex] = [:]
        }

        // Add a point to the talent
        let currentPoints = selectedTalents[specIndex]?[talent.id] ?? 0
        selectedTalents[specIndex]?[talent.id] = currentPoints + 1

        // Update available points
        updateAvailablePoints()
    }

    /// Unlearn a talent (remove a point)
    private func unlearnTalent(talent: ClassData.Talent, specIndex: Int) {
        guard canUnlearnTalent(talent: talent, specIndex: specIndex) else { return }

        // Remove a point from the talent
        if let currentPoints = selectedTalents[specIndex]?[talent.id], currentPoints > 0 {
            selectedTalents[specIndex]?[talent.id] = currentPoints - 1

            // If no points left, remove from dictionary
            if selectedTalents[specIndex]?[talent.id] == 0 {
                selectedTalents[specIndex]?.removeValue(forKey: talent.id)
            }

            // Update available points
            updateAvailablePoints()
        }
    }

    /// Reset all talents
    private func resetTalents() {
        selectedTalents = [0: [:], 1: [:], 2: [:]]
        updateAvailablePoints()
    }

    /// Update available talent points based on character level and spent points
    private func updateAvailablePoints() {
        let total = totalPointsForLevel(characterLevel)
        availablePoints = total - spentPoints
    }

    /// Calculate total available talent points for a level
    private func totalPointsForLevel(_ level: Int) -> Int {
        return max(0, level - 9)  // First point at level 10
    }

    /// Calculate spent talent points
    private var spentPoints: Int {
        let spent = selectedTalents.values.flatMap { $0.values }.reduce(0, +)
        return spent
    }

    /// Color for talent node background
    private func talentBackgroundColor(talent: ClassData.Talent, currentPoints: Int, specIndex: Int)
        -> Color
    {
        if currentPoints == talent.ranks {
            return Color.green.opacity(0.7)  // Maxed out
        } else if currentPoints > 0 {
            return Color.blue.opacity(0.7)  // Partially learned
        } else if canLearnTalent(talent: talent, specIndex: specIndex) {
            return Color.orange.opacity(0.5)  // Available
        } else {
            return Color.gray.opacity(0.5)  // Unavailable
        }
    }

    /// Generate an icon name for a talent
    private func getIconName(for talent: ClassData.Talent) -> String {
        let icons = [
            "bolt.fill", "flame.fill", "drop.fill", "shield.fill",
            "heart.fill", "cross.fill", "wand.and.stars", "scope",
            "target", "bolt.horizontal.fill", "bolt.slash.fill",
            "sun.max.fill", "sparkles", "star.fill", "tornado",
        ]

        // Use talent ID as a seed for consistent icons
        return icons[talent.id % icons.count]
    }

    /// Save current build
    private func saveBuild() {
        guard !buildName.isEmpty else { return }

        // Get class name
        let className = classes.first { $0.id == selectedClassID }?.name ?? "Unknown"

        // Calculate points in each tree
        let points = [0, 1, 2].map { specIndex in
            selectedTalents[specIndex]?.values.reduce(0, +) ?? 0
        }

        // Create build
        let build = TalentBuild(
            id: UUID(),
            name: buildName,
            classID: selectedClassID,
            className: className,
            talentData: selectedTalents,
            points: points
        )

        // Add to saved builds
        savedBuilds.append(build)

        // Reset build name
        buildName = ""

        // In a real app, would save to persistent storage
    }

    /// Load a saved build
    private func loadBuild(_ build: TalentBuild) {
        // Set class
        selectedClassID = build.classID

        // Set talents
        selectedTalents = build.talentData

        // Update available points
        updateAvailablePoints()
    }

    /// Share current build
    private func shareBuild() {
        // In a real app, this would generate a shareable string or link

        // Example: Create a simple build code
        let className = classes.first { $0.id == selectedClassID }?.name ?? "Unknown"

        // Points in each tree
        let points = [0, 1, 2].map { specIndex in
            selectedTalents[specIndex]?.values.reduce(0, +) ?? 0
        }

        let buildCode = "\(className) \(points[0])/\(points[1])/\(points[2])"

        // Share the build code
        let activityVC = UIActivityViewController(
            activityItems: [buildCode],
            applicationActivities: nil
        )

        // Present the share sheet
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let rootViewController = windowScene.windows.first?.rootViewController
        {
            rootViewController.present(activityVC, animated: true)
        }
    }

    /// Show additional build information
    private func showBuildInfo() {
        // In a real app, this would show a detailed view with build stats

        // For now, just show an alert with basic info
        let className = classes.first { $0.id == selectedClassID }?.name ?? "Unknown"

        // Points in each tree
        let points = [0, 1, 2].map { specIndex in
            selectedTalents[specIndex]?.values.reduce(0, +) ?? 0
        }

        // Create build code string (used in message below)
        let buildCode = "\(className) \(points[0])/\(points[1])/\(points[2])"

        // Get spec names
        let specNames = classes.first { $0.id == selectedClassID }?.specs.map { $0.name } ?? []

        // Create message
        var message = "Class: \(className)\n"
        message += "Build code: \(buildCode)\n\n"

        for i in 0..<min(3, specNames.count) {
            message += "\(specNames[i]): \(points[i]) points\n"
        }

        // Show alert
        let alert = UIAlertController(
            title: "Build Info",
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "OK", style: .default))

        // Present the alert
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let rootViewController = windowScene.windows.first?.rootViewController
        {
            rootViewController.present(alert, animated: true)
        }
    }
}

// MARK: - Models

/// Talent build information
struct TalentBuild: Identifiable {
    let id: UUID
    let name: String
    let classID: Int
    let className: String
    let talentData: [Int: [Int: Int]]  // [specIndex: [talentID: points]]
    let points: [Int]  // Points in each tree
}

/// Class data structure
struct ClassData: Identifiable {
    let id: Int
    let name: String
    let powerType: String
    let specs: [Spec]

    struct Spec {
        let name: String
        let talents: [Talent]
    }

    struct Talent: Identifiable {
        let id: Int
        let name: String
        let tier: Int
        let column: Int
        let ranks: Int
        let prerequisiteID: Int?
    }
}

// MARK: - Extensions

extension Array {
    /// Safe subscript that returns nil instead of crashing on out-of-bounds
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

struct TalentCalculatorView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TalentCalculatorView()
        }
    }
}
