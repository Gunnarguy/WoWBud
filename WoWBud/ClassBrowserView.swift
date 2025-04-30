//
//  ClassBrowserView.swift
//  WoWBud
//
//  Created on 4/30/25.
//

import SwiftUI

struct ClassBrowserView: View {
    // Selected class
    @State private var selectedClassID: Int = 1  // Warrior by default
    
    // Selected race filter
    @State private var selectedFaction: Faction? = nil
    
    // Show abilities mode
    @State private var showingClassAbilities: Bool = false
    
    // Classes and races data
    @State private var classes: [ClassicClass] = []
    @State private var races: [ClassicRace] = []
    
    // Loading state
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Class selection chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    Spacer().frame(width: 4)
                    
                    ForEach(classes) { wowClass in
                        classSelectionChip(wowClass)
                    }
                    
                    Spacer().frame(width: 4)
                }
                .padding(.vertical, 12)
            }
            .background(Color(.secondarySystemBackground))
            
            // Faction filter
            HStack(spacing: 20) {
                // Alliance button
                Button(action: {
                    selectedFaction = selectedFaction == .alliance ? nil : .alliance
                }) {
                    HStack {
                        Image(systemName: "shield.fill")
                            .foregroundColor(.blue)
                        
                        Text("Alliance")
                            .font(.subheadline)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(selectedFaction == .alliance ? Color.blue.opacity(0.2) : Color.clear)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.blue, lineWidth: selectedFaction == .alliance ? 2 : 1)
                    )
                }
                
                // Horde button
                Button(action: {
                    selectedFaction = selectedFaction == .horde ? nil : .horde
                }) {
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.red)
                        
                        Text("Horde")
                            .font(.subheadline)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(selectedFaction == .horde ? Color.red.opacity(0.2) : Color.clear)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.red, lineWidth: selectedFaction == .horde ? 2 : 1)
                    )
                }
                
                Spacer()
                
                // Toggle for abilities/races view
                Button(action: {
                    withAnimation {
                        showingClassAbilities.toggle()
                    }
                }) {
                    HStack {
                        Image(systemName: showingClassAbilities ? "person.fill" : "bolt.fill")
                        
                        Text(showingClassAbilities ? "Races" : "Abilities")
                            .font(.subheadline)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.purple.opacity(0.2))
                    .cornerRadius(20)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // Main content
            if isLoading {
                Spacer()
                ProgressView("Loading...")
                Spacer()
            } else if let errorMessage = errorMessage {
                Spacer()
                Text(errorMessage)
                    .foregroundColor(.red)
                Spacer()
            } else {
                if showingClassAbilities {
                    classAbilitiesView
                } else {
                    classRacesView
                }
            }
        }
        .navigationTitle("Classic Classes")
        .onAppear {
            loadClassData()
        }
    }
    
    // MARK: - Subviews
    
    /// Selection chip for a class
    private func classSelectionChip(_ wowClass: ClassicClass) -> some View {
        Button(action: {
            selectedClassID = wowClass.id
        }) {
            VStack(spacing: 8) {
                // Class icon
                ZStack {
                    Circle()
                        .fill(wowClass.id == selectedClassID ? wowClass.color : Color.gray.opacity(0.3))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: wowClass.iconName)
                        .font(.title3)
                        .foregroundColor(.white)
                }
                
                // Class name
                Text(wowClass.name)
                    .font(.caption)
                    .foregroundColor(wowClass.id == selectedClassID ? wowClass.color : .primary)
            }
            .frame(width: 70)
            .padding(.bottom, 4)
        }
    }
    
    /// View for displaying compatible races
    private var classRacesView: some View {
        let selectedClass = classes.first { $0.id == selectedClassID }
        let compatibleRaces = races.filter { race in
            // Filter by faction if selected
            if let faction = selectedFaction, race.faction != faction {
                return false
            }
            
            // Filter by class compatibility
            return selectedClass?.compatibleRaces.contains(race.id) ?? false
        }
        
        return ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Class header
                if let selectedClass = selectedClass {
                    classHeaderView(selectedClass)
                }
                
                // Races section
                VStack(alignment: .leading, spacing: 16) {
                    // Section header
                    Text("Playable Races")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if compatibleRaces.isEmpty {
                        Text("No races match your filters")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ForEach(compatibleRaces) { race in
                            raceRow(race)
                        }
                    }
                }
                
                // Armor and weapons section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Armor & Weapons")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if let selectedClass = selectedClass {
                        // Armor types
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Armor Proficiency")
                                .font(.subheadline)
                                .padding(.horizontal)
                            
                            armorTypesRow(for: selectedClass)
                        }
                        
                        Divider()
                            .padding(.horizontal)
                        
                        // Weapon types
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Weapon Proficiency")
                                .font(.subheadline)
                                .padding(.horizontal)
                            
                            weaponTypesRow(for: selectedClass)
                        }
                    }
                }
                .padding(.vertical)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Anniversary features
                VStack(alignment: .leading, spacing: 12) {
                    Text("Anniversary Features")
                        .font(.headline)
                    
                    HStack {
                        Image(systemName: "person.2")
                            .foregroundColor(.green)
                        
                        Text("Dual Spec Coming Soon")
                            .font(.subheadline)
                    }
                    
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        
                        Text("No Buff/Debuff Limit")
                            .font(.subheadline)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer(minLength: 40)
            }
            .padding(.vertical)
        }
    }
    
    /// View for displaying class abilities
    private var classAbilitiesView: some View {
        let selectedClass = classes.first { $0.id == selectedClassID }
        
        return ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Class header
                if let selectedClass = selectedClass {
                    classHeaderView(selectedClass)
                }
                
                // Abilities section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Core Abilities")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if let selectedClass = selectedClass, !selectedClass.coreAbilities.isEmpty {
                        ForEach(selectedClass.coreAbilities) { ability in
                            abilityRow(ability)
                        }
                    } else {
                        Text("No abilities data available")
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
                
                // Specializations section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Specializations")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if let selectedClass = selectedClass {
                        ForEach(selectedClass.specs) { spec in
                            specRow(spec)
                        }
                    }
                }
                .padding(.vertical)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Class role section
                if let selectedClass = selectedClass {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Class Roles")
                            .font(.headline)
                        
                        HStack(spacing: 20) {
                            ForEach(selectedClass.roles, id: \.self) { role in
                                VStack {
                                    Image(systemName: iconForRole(role))
                                        .font(.title2)
                                        .foregroundColor(colorForRole(role))
                                        .frame(width: 40, height: 40)
                                        .background(colorForRole(role).opacity(0.2))
                                        .cornerRadius(20)
                                    
                                    Text(role)
                                        .font(.caption)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                Spacer(minLength: 40)
            }
            .padding(.vertical)
        }
    }
    
    /// Class header view
    private func classHeaderView(_ wowClass: ClassicClass) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Class icon
                ZStack {
                    Circle()
                        .fill(wowClass.color)
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: wowClass.iconName)
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                // Class details
                VStack(alignment: .leading, spacing: 4) {
                    Text(wowClass.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Resource: \(wowClass.powerType)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Class description
            Text(wowClass.description)
                .font(.body)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    /// Race row view
    private func raceRow(_ race: ClassicRace) -> some View {
        HStack(spacing: 16) {
            // Race icon
            ZStack {
                Circle()
                    .fill(race.faction == .alliance ? Color.blue.opacity(0.2) : Color.red.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: race.iconName)
                    .font(.title3)
                    .foregroundColor(race.faction == .alliance ? .blue : .red)
            }
            
            // Race details
            VStack(alignment: .leading, spacing: 4) {
                Text(race.name)
                    .font(.headline)
                
                Text(race.faction.rawValue)
                    .font(.subheadline)
                    .foregroundColor(race.faction == .alliance ? .blue : .red)
            }
            
            Spacer()
            
            // Racial details button
            Button(action: {
                // Would show racial details in a real app
            }) {
                Image(systemName: "info.circle")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    /// Ability row view
    private func abilityRow(_ ability: ClassicAbility) -> some View {
        HStack(spacing: 16) {
            // Ability icon
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.black)
                    .frame(width: 40, height: 40)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray, lineWidth: 1)
                    )
                
                Text(String(ability.name.prefix(1)))
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            // Ability details
            VStack(alignment: .leading, spacing: 4) {
                Text(ability.name)
                    .font(.headline)
                
                if let level = ability.level {
                    Text("Available at level \(level)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(ability.description)
                    .font(.body)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    /// Specialization row view
    private func specRow(_ spec: ClassicSpec) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Spec icon
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: spec.iconName)
                        .font(.headline)
                        .foregroundColor(.purple)
                }
                
                Text(spec.name)
                    .font(.headline)
                
                Spacer()
                
                // Role icons
                HStack(spacing: 8) {
                    ForEach(spec.roles, id: \.self) { role in
                        Image(systemName: iconForRole(role))
                            .foregroundColor(colorForRole(role))
                    }
                }
            }
            
            Text(spec.description)
                .font(.subheadline)
                .lineLimit(3)
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    /// Armor types row
    private func armorTypesRow(for wowClass: ClassicClass) -> some View {
        HStack(spacing: 20) {
            ForEach(ArmorType.allCases) { armorType in
                VStack {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(wowClass.armorTypes.contains(armorType) ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: armorType.iconName)
                            .foregroundColor(wowClass.armorTypes.contains(armorType) ? .blue : .gray)
                    }
                    
                    // Name
                    Text(armorType.rawValue)
                        .font(.caption)
                        .foregroundColor(wowClass.armorTypes.contains(armorType) ? .primary : .secondary)
                }
            }
        }
        .padding(.horizontal)
    }
    
    /// Weapon types row
    private func weaponTypesRow(for wowClass: ClassicClass) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(WeaponType.allCases) { weaponType in
                    VStack {
                        // Icon
                        ZStack {
                            Circle()
                                .fill(wowClass.weaponTypes.contains(weaponType) ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: weaponType.iconName)
                                .foregroundColor(wowClass.weaponTypes.contains(weaponType) ? .blue : .gray)
                        }
                        
                        // Name
                        Text(weaponType.rawValue)
                            .font(.caption)
                            .foregroundColor(wowClass.weaponTypes.contains(weaponType) ? .primary : .secondary)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Helper functions
    
    /// Load class and race data
    private func loadClassData() {
        isLoading = true
        errorMessage = nil
        
        // In a real app, this would fetch from ClassicAPIService
        // For now, simulate with mock data
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Load mock data
            self.classes = self.createMockClasses()
            self.races = self.createMockRaces()
            
            self.isLoading = false
        }
    }
    
    /// Get icon name for a role
    private func iconForRole(_ role: String) -> String {
        switch role {
        case "Tank": return "shield.fill"
        case "Healer": return "cross.fill"
        case "DPS": return "bolt.fill"
        default: return "questionmark"
        }
    }
    
    /// Get color for a role
    private func colorForRole(_ role: String) -> Color {
        switch role {
        case "Tank": return .blue
        case "Healer": return .green
        case "DPS": return .red
        default: return .gray
        }
    }
    
    // MARK: - Mock Data
    
    /// Create mock classes
    private func createMockClasses() -> [ClassicClass] {
        return [
            ClassicClass(
                id: 1,
                name: "Warrior",
                iconName: "shield",
                color: Color(hex: "#C79C6E"),
                powerType: "Rage",
                description: "Warriors are melee fighters, skilled in the use of many weapons and armor types. They can spec to tank, deal damage, or a hybrid of both.",
                compatibleRaces: [1, 2, 3, 4, 5, 6, 7, 8],
                armorTypes: [.cloth, .leather, .mail, .plate],
                weaponTypes: [.oneHandedSword, .twoHandedSword, .oneHandedAxe, .twoHandedAxe, .oneHandedMace, .twoHandedMace, .polearm, .staff, .dagger, .shield, .bow, .crossbow, .gun, .thrown],
                roles: ["Tank", "DPS"],
                coreAbilities: [
                    ClassicAbility(id: 101, name: "Heroic Strike", level: 1, description: "An instant strike that causes increased damage."),
                    ClassicAbility(id: 102, name: "Battle Shout", level: 1, description: "Increases attack power of all party members within 20 yards."),
                    ClassicAbility(id: 103, name: "Charge", level: 4, description: "Charges an enemy, generating rage and stunning it."),
                    ClassicAbility(id: 104, name: "Shield Block", level: 10, description: "Increases chance to block for 5 sec.")
                ],
                specs: [
                    ClassicSpec(
                        id: 1,
                        name: "Arms",
                        iconName: "bolt.fill",
                        description: "A master of two-handed weapons, using mobility and control to deal damage.",
                        roles: ["DPS"]
                    ),
                    ClassicSpec(
                        id: 2,
                        name: "Fury",
                        iconName: "flame.fill",
                        description: "Dual-wielding berserker unleashing a flurry of attacks.",
                        roles: ["DPS"]
                    ),
                    ClassicSpec(
                        id: 3,
                        name: "Protection",
                        iconName: "shield.fill",
                        description: "Uses a shield to protect allies and maintain aggro on enemies.",
                        roles: ["Tank"]
                    )
                ]
            ),
            ClassicClass(
                id: 5,
                name: "Priest",
                iconName: "cross.fill",
                color: Color(hex: "#FFFFFF"),
                powerType: "Mana",
                description: "Priests are spiritual leaders of their people, using the power of light and shadow to heal allies and harm enemies.",
                compatibleRaces: [1, 3, 4, 5, 7, 8, 10, 11],
                armorTypes: [.cloth],
                weaponTypes: [.oneHandedMace, .staff, .dagger, .wand],
                roles: ["Healer", "DPS"],
                coreAbilities: [
                    ClassicAbility(id: 501, name: "Lesser Heal", level: 1, description: "Heals a friendly target for a moderate amount."),
                    ClassicAbility(id: 502, name: "Power Word: Shield", level: 6, description: "Shields a friendly target, absorbing damage."),
                    ClassicAbility(id: 503, name: "Shadow Word: Pain", level: 4, description: "A word of darkness that causes damage over time.")
                ],
                specs: [
                    ClassicSpec(
                        id: 51,
                        name: "Discipline",
                        iconName: "shield.fill",
                        description: "Uses shields and preventative healing to protect allies.",
                        roles: ["Healer"]
                    ),
                    ClassicSpec(
                        id: 52,
                        name: "Holy",
                        iconName: "sun.max.fill",
                        description: "Versatile healer with powerful single-target and area healing.",
                        roles: ["Healer"]
                    ),
                    ClassicSpec(
                        id: 53,
                        name: "Shadow",
                        iconName: "moon.stars.fill",
                        description: "Wields the power of shadow to damage enemies and drain their life force.",
                        roles: ["DPS"]
                    )
                ]
            ),
            ClassicClass(
                id: 8,
                name: "Mage",
                iconName: "sparkles",
                color: Color(hex: "#69CCF0"),
                powerType: "Mana",
                description: "Mages wield arcane, fire, and frost magic to destroy enemies and control the battlefield.",
                compatibleRaces: [1, 3, 5, 7, 8, 10, 11],
                armorTypes: [.cloth],
                weaponTypes: [.staff, .dagger, .wand, .sword],
                roles: ["DPS"],
                coreAbilities: [
                    ClassicAbility(id: 801, name: "Fireball", level: 1, description: "Hurls a fiery ball that causes fire damage."),
                    ClassicAbility(id: 802, name: "Frost Armor", level: 1, description: "Increases armor and slows attackers.")
                ],
                specs: [
                    ClassicSpec(
                        id: 81,
                        name: "Arcane",
                        iconName: "sparkles",
                        description: "Manipulates mana and arcane energies to deal damage.",
                        roles: ["DPS"]
                    ),
                    ClassicSpec(
                        id: 82,
                        name: "Fire",
                        iconName: "flame.fill",
                        description: "Focuses on fire spells for high damage output.",
                        roles: ["DPS"]
                    ),
                    ClassicSpec(
                        id: 83,
                        name: "Frost",
                        iconName: "snowflake",
                        description: "Uses ice magic to control enemies and deal damage.",
                        roles: ["DPS"]
                    )
                ]
            ),
            ClassicClass(
                id: 4,
                name: "Rogue",
                iconName: "person.fill.viewfinder",
                color: Color(hex: "#FFF569"),
                powerType: "Energy",
                description: "Masters of stealth who specialize in assassination and close combat.",
                compatibleRaces: [1, 2, 3, 4, 5, 7, 8, 10],
                armorTypes: [.cloth, .leather],
                weaponTypes: [.dagger, .oneHandedSword, .oneHandedMace, .fistWeapon, .thrown],
                roles: ["DPS"],
                coreAbilities: [
                    ClassicAbility(id: 401, name: "Sinister Strike", level: 1, description: "A quick strike that causes physical damage."),
                    ClassicAbility(id: 402, name: "Stealth", level: 1, description: "Puts you in stealth mode, reducing detection chance.")
                ],
                specs: [
                    ClassicSpec(
                        id: 41,
                        name: "Assassination",
                        iconName: "trash.fill",
                        description: "Specializes in poisons and daggers for lethal strikes.",
                        roles: ["DPS"]
                    ),
                    ClassicSpec(
                        id: 42,
                        name: "Combat",
                        iconName: "sword",
                        description: "A master of weapons focusing on sustained damage.",
                        roles: ["DPS"]
                    ),
                    ClassicSpec(
                        id: 43,
                        name: "Subtlety",
                        iconName: "eye.slash",
                        description: "Uses stealth and deception to ambush enemies.",
                        roles: ["DPS"]
                    )
                ]
            )
        ]
    }
    
    /// Create mock races
    private func createMockRaces() -> [ClassicRace] {
        return [
            ClassicRace(id: 1, name: "Human", faction: .alliance, iconName: "person.crop.circle", racials: ["Diplomacy", "Perception", "The Human Spirit", "Sword Specialization", "Mace Specialization"]),
            ClassicRace(id: 2, name: "Orc", faction: .horde, iconName: "person.crop.circle.badge.xmark", racials: ["Blood Fury", "Hardiness", "Command", "Axe Specialization"]),
            ClassicRace(id: 3, name: "Dwarf", faction: .alliance, iconName: "person.crop.circle.fill.badge.plus", racials: ["Gun Specialization", "Frost Resistance", "Stone Form", "Find Treasure"]),
            ClassicRace(id: 4, name: "Night Elf", faction: .alliance, iconName: "moon.stars.fill", racials: ["Shadowmeld", "Quickness", "Wisp Spirit", "Nature Resistance"]),
            ClassicRace(id: 5, name: "Undead", faction: .horde, iconName: "cross.circle", racials: ["Will of the Forsaken", "Cannibalize", "Underwater Breathing", "Shadow Resistance"]),
            ClassicRace(id: 6, name: "Tauren", faction: .horde, iconName: "hare.fill", racials: ["War Stomp", "Endurance", "Nature Resistance", "Cultivation"]),
            ClassicRace(id: 7, name: "Gnome", faction: .alliance, iconName: "gear", racials: ["Escape Artist", "Expansive Mind", "Engineering Specialist", "Arcane Resistance"]),
            ClassicRace(id: 8, name: "Troll", faction: .horde, iconName: "arrow.up.and.down", racials: ["Berserking", "Regeneration", "Beast Slaying", "Throwing Specialization", "Bow Specialization"])
        ]
    }
}

// MARK: - Models

/// Class data for Classic WoW
struct ClassicClass: Identifiable {
    let id: Int
    let name: String
    let iconName: String
    let color: Color
    let powerType: String
    let description: String
    let compatibleRaces: [Int]
    let armorTypes: [ArmorType]
    let weaponTypes: [WeaponType]
    let roles: [String]
    let coreAbilities: [ClassicAbility]
    let specs: [ClassicSpec]
}

/// Race data for Classic WoW
struct ClassicRace: Identifiable {
    let id: Int
    let name: String
    let faction: Faction
    let iconName: String
    let racials: [String]
}

/// Ability data
struct ClassicAbility: Identifiable {
    let id: Int
    let name: String
    let level: Int?
    let description: String
}

/// Specialization data
struct ClassicSpec: Identifiable {
    let id: Int
    let name: String
    let iconName: String
    let description: String
    let roles: [String]
}

/// Faction enum
enum Faction: String {
    case alliance = "Alliance"
    case horde = "Horde"
}

/// Armor type enum
enum ArmorType: String, CaseIterable, Identifiable {
    case cloth = "Cloth"
    case leather = "Leather"
    case mail = "Mail"
    case plate = "Plate"
    
    var id: String { self.rawValue }
    
    var iconName: String {
        switch self {
        case .cloth: return "tshirt"
        case .leather: return "person.crop.circle"
        case .mail: return "link"
        case .plate: return "shield.lefthalf.filled"
        }
    }
}

/// Weapon type enum
enum WeaponType: String, CaseIterable, Identifiable {
    case dagger = "Dagger"
    case oneHandedSword = "1H Sword"
    case twoHandedSword = "2H Sword"
    case oneHandedMace = "1H Mace"
    case twoHandedMace = "2H Mace"
    case oneHandedAxe = "1H Axe"
    case twoHandedAxe = "2H Axe"
    case staff = "Staff"
    case polearm = "Polearm"
    case fistWeapon = "Fist Weapon"
    case bow = "Bow"
    case crossbow = "Crossbow"
    case gun = "Gun"
    case thrown = "Thrown"
    case wand = "Wand"
    case shield = "Shield"
    
    var id: String { self.rawValue }
    
    var iconName: String {
        switch self {
        case .dagger: return "scissors"
        case .oneHandedSword: return "slash"
        case .twoHandedSword: return "slash.circle"
        case .oneHandedMace: return "hammer"
        case .twoHandedMace: return "hammer.circle"
        case .oneHandedAxe: return "scissors"
        case .twoHandedAxe: return "scissors.circle"
        case .staff: return "arrow.up"
        case .polearm: return "arrow.up.to.line"
        case .fistWeapon: return "hand.raised"
        case .bow: return "lasso"
        case .crossbow: return "scope"
        case .gun: return "scope"
        case .thrown: return "arrow.up.forward"
        case .wand: return "sparkles"
        case .shield: return "shield"
        }
    }
}

// MARK: - Utility Extensions

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct ClassBrowserView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ClassBrowserView()
        }
    }
}
