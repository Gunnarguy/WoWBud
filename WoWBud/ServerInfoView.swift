//
//  ServerInfoView.swift
//  WoWBud
//
//  Created on 4/30/25.
//

import SwiftUI

struct ServerInfoView: View {
    // Selected region
    @State private var selectedRegion: Region = .us

    // Selected server type
    @State private var selectedServerType: ServerType = .pve

    // Server data
    @State private var servers: [ClassicServer] = []

    // Selected server for detail view
    @State private var selectedServer: ClassicServer? = nil
    @State private var showingServerDetail: Bool = false

    // Server status (mock data, would be fetched from API)
    @State private var serverStatus: [String: ServerStatus] = [:]

    var body: some View {
        VStack(spacing: 0) {
            // Region selector
            Picker("Region", selection: $selectedRegion) {
                Text("Americas").tag(Region.us)
                Text("Europe").tag(Region.eu)

            }
            .pickerStyle(.segmented)
            .padding()
            .onChange(of: selectedRegion) { oldValue, newValue in
                // Update server list for selected region
                updateServerList()
            }

            // Server type selector
            Picker("Server Type", selection: $selectedServerType) {
                Text("PvE").tag(ServerType.pve)
                Text("PvP").tag(ServerType.pvp)
                Text("Hardcore").tag(ServerType.hardcore)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.bottom)
            .onChange(of: selectedServerType) { oldValue, newValue in
                // Filter server list for selected type
                updateServerList()
            }

            // Server list
            List {
                ForEach(filteredServers) { server in
                    serverRow(server)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedServer = server
                            showingServerDetail = true
                        }
                }
            }
            .listStyle(.plain)

            // Footer
            VStack(spacing: 4) {
                Text("20th Anniversary Classic Servers")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemBackground))
        }
        .sheet(isPresented: $showingServerDetail) {
            if let server = selectedServer {
                serverDetailView(server)
            }
        }
        .navigationTitle("Anniversary Servers")
        .onAppear {
            // Load initial server data
            loadServerData()

            // Set up mock status data
            setupMockServerStatus()
        }
    }

    // MARK: - Subviews

    /// Row view for a server in the list
    private func serverRow(_ server: ClassicServer) -> some View {
        HStack {
            // Server icon based on type
            ZStack {
                Circle()
                    .fill(server.type.color.opacity(0.2))
                    .frame(width: 40, height: 40)

                Image(systemName: server.type.iconName)
                    .foregroundColor(server.type.color)
            }

            // Server info
            VStack(alignment: .leading, spacing: 4) {
                Text(server.name)
                    .font(.headline)

                HStack {
                    Text(server.type.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(server.region.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Status indicator
            serverStatusIndicator(for: server.name)
        }
        .padding(.vertical, 4)
    }

    /// Status indicator view for a server
    private func serverStatusIndicator(for serverName: String) -> some View {
        let status = serverStatus[serverName] ?? .unknown

        return HStack {
            Circle()
                .fill(status.color)
                .frame(width: 10, height: 10)

            Text(status.description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    /// Detail view for a selected server
    private func serverDetailView(_ server: ClassicServer) -> some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                // Server header
                HStack(spacing: 16) {
                    // Server icon
                    ZStack {
                        Circle()
                            .fill(server.type.color.opacity(0.2))
                            .frame(width: 60, height: 60)

                        Image(systemName: server.type.iconName)
                            .font(.title2)
                            .foregroundColor(server.type.color)
                    }

                    // Server info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(server.name)
                            .font(.title2)
                            .fontWeight(.bold)

                        HStack {
                            Text(server.type.rawValue)
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Text("•")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Text(server.region.displayName)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)

                // Server status section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Server Status")
                        .font(.headline)

                    HStack(spacing: 16) {
                        // Current status
                        let status = serverStatus[server.name] ?? .unknown

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Current Status")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            HStack {
                                Circle()
                                    .fill(status.color)
                                    .frame(width: 10, height: 10)

                                Text(status.description)
                                    .font(.body)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        // Population
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Population")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Text(server.population)
                                .font(.body)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)

                // Server features section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Server Features")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 8) {
                        featureRow(
                            icon: "calendar", title: "Launched", description: "November 21, 2024")

                        if server.type == .hardcore {
                            featureRow(
                                icon: "exclamationmark.triangle", title: "Character Death",
                                description: "Permanent - One life only")
                            featureRow(
                                icon: "arrow.left.arrow.right", title: "Character Transfer",
                                description: "Allowed to PvE after death")
                            featureRow(
                                icon: "clock.arrow.circlepath", title: "End State",
                                description: "Remains in Classic Era")
                        } else {
                            featureRow(
                                icon: "bolt.horizontal", title: "Progression",
                                description: "Classic → The Burning Crusade")
                            featureRow(
                                icon: "person.2", title: "Dual Spec",
                                description: "Available (coming soon)")
                            featureRow(
                                icon: "shield.checkerboard", title: "Buff Limits",
                                description: "Removed for modern experience")
                        }

                        featureRow(
                            icon: "envelope", title: "Mail Delivery",
                            description: "Instant between alt characters")
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)

                // Nearby realms
                if let nearbyServers = getNearbyServers(for: server) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Other Anniversary Realms")
                            .font(.headline)

                        ForEach(nearbyServers) { nearbyServer in
                            Button(action: {
                                selectedServer = nearbyServer
                            }) {
                                HStack {
                                    Image(systemName: nearbyServer.type.iconName)
                                        .foregroundColor(nearbyServer.type.color)

                                    Text(nearbyServer.name)

                                    Spacer()

                                    Text(nearbyServer.type.rawValue)
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Server Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingServerDetail = false
                    }
                }
            }
        }
    }

    /// Row view for a server feature
    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 24, height: 24)
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)

                Text(description)
                    .font(.body)
            }
        }
    }

    // MARK: - Helper functions

    /// Load server data
    private func loadServerData() {
        // In a real app, this would fetch from an API
        // For now, using hardcoded data from 20th Anniversary servers
        servers = [
            // NA Servers
            ClassicServer(id: 1, name: "Dreamscythe", type: .pve, region: .us, population: "High"),
            ClassicServer(id: 2, name: "Nightslayer", type: .pvp, region: .us, population: "Full"),
            ClassicServer(
                id: 3, name: "Doomhowl", type: .hardcore, region: .us, population: "Medium"),

            // EU Servers
            ClassicServer(
                id: 4, name: "Thunderstrike", type: .pve, region: .eu, population: "High"),
            ClassicServer(id: 5, name: "Spineshatter", type: .pvp, region: .eu, population: "Full"),
            ClassicServer(
                id: 6, name: "Soulseeker", type: .hardcore, region: .eu, population: "Medium"),

        ]
    }

    /// Update server list based on selected region and type
    private func updateServerList() {
        // In a real app, this would fetch fresh data
        // For now, just filtering the existing data
    }

    /// Get nearby servers in the same region but different types
    private func getNearbyServers(for server: ClassicServer) -> [ClassicServer]? {
        let sameRegionServers = servers.filter { $0.region == server.region && $0.id != server.id }
        return sameRegionServers.isEmpty ? nil : sameRegionServers
    }

    /// Set up mock server status data
    private func setupMockServerStatus() {
        // In a real app, this would be fetched from the Blizzard API
        for server in servers {
            // Randomly assign status
            let randomValue = Int.random(in: 0...10)
            let status: ServerStatus

            if randomValue < 7 {
                status = .online
            } else if randomValue < 9 {
                status = .highPopulation
            } else {
                status = .queueActive
            }

            serverStatus[server.name] = status
        }
    }

    /// Get filtered servers based on selected region and type
    private var filteredServers: [ClassicServer] {
        servers.filter { $0.region == selectedRegion && $0.type == selectedServerType }
    }
}

// MARK: - Models

/// Model for a Classic server
struct ClassicServer: Identifiable {
    let id: Int
    let name: String
    let type: ServerType
    let region: Region
    let population: String
}

/// Enum for server types
enum ServerType: String {
    case pve = "PvE"
    case pvp = "PvP"
    case hardcore = "Hardcore"

    var color: Color {
        switch self {
        case .pve: return .blue
        case .pvp: return .red
        case .hardcore: return .purple
        }
    }

    var iconName: String {
        switch self {
        case .pve: return "person.2"
        case .pvp: return "shield"
        case .hardcore: return "exclamationmark.triangle"
        }
    }
}

/// Extension to add display name to Region
extension Region {
    var displayName: String {
        switch self {
        case .us: return "Americas"
        case .eu: return "Europe"

        }
    }
}

/// Enum for server status
enum ServerStatus {
    case online
    case highPopulation
    case queueActive
    case maintenance
    case unknown

    var description: String {
        switch self {
        case .online: return "Online"
        case .highPopulation: return "High Population"
        case .queueActive: return "Queue Active"
        case .maintenance: return "Maintenance"
        case .unknown: return "Unknown"
        }
    }

    var color: Color {
        switch self {
        case .online: return .green
        case .highPopulation: return .yellow
        case .queueActive: return .orange
        case .maintenance: return .red
        case .unknown: return .gray
        }
    }
}

struct ServerInfoView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ServerInfoView()
        }
    }
}
