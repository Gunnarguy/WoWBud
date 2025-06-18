//
//  ContentView.swift
//  WoWBud
//
//  Created on 4/30/25.
//

import SwiftUI

struct ContentView: View {
    // State for tracking the selected tab
    @State private var selectedTab = 0
    
    // State to control the presentation of the settings sheet
    @State private var showingSettings = false
    
    // State to track OAuth token status
    @State private var tokenStatus: TokenStatus = .unknown
    
    // Check for credentials
    private var hasCredentials: Bool {
        return Secrets.clientID != "<INSERT-CLIENT-ID>" &&
               Secrets.clientSecret != "<INSERT-CLIENT-SECRET>"
    }
    
    var body: some View {
        Group {
            if !hasCredentials {
                // Show credentials prompt if not set
                credentialsPromptView
            } else if tokenStatus == .loading {
                // Show loading view while fetching token
                ProgressView("Authenticating with Blizzard...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if tokenStatus == .error {
                // Show error view if token fetch failed
                tokenErrorView
            } else {
                // Main TabView for navigation
                TabView(selection: $selectedTab) {

                    
                    // Item browser tab
                    ItemLookupView()
                        .tabItem {
                            Image(systemName: "shield")
                            Text("Items")
                        }
                        .tag(1)
                    
                    // Classes and races
                    ClassBrowserView()
                        .tabItem {
                            Image(systemName: "person.fill")
                            Text("Classes")
                        }
                        .tag(2)
                    
                    // Reset timers
                    ResetTimerView()
                        .tabItem {
                            Image(systemName: "clock")
                            Text("Resets")
                        }
                        .tag(3)
                    
                    // Server info
                    ServerInfoView()
                        .tabItem {
                            Image(systemName: "network")
                            Text("Servers")
                        }
                        .tag(4)
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .onDisappear {
                    // Check for credentials changes after settings view is dismissed
                    if hasCredentials && (tokenStatus == .unknown || tokenStatus == .error) {
                        Task {
                            await fetchOAuthToken()
                        }
                    }
                }
        }
        .onAppear {
            // Check for credentials and OAuth token on app launch
            if hasCredentials && Secrets.oauthToken.isEmpty {
                Task {
                    await fetchOAuthToken()
                }
            } else if hasCredentials && !Secrets.oauthToken.isEmpty {
                // Token already exists
                tokenStatus = .success
            }
        }
        .toolbar {
            if hasCredentials {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gear")
                }
            }
        }
    }
    
    /// View that prompts the user to enter API credentials
    private var credentialsPromptView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.shield")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("WoW Classic 20th Anniversary")
                .font(.title)
                .fontWeight(.bold)
            
            Text("API Credentials Needed")
                .font(.headline)
            
            Text("Please enter your Blizzard API Client ID and Secret to use this app.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Open Settings") {
                showingSettings = true
            }
            .buttonStyle(.borderedProminent)
            .padding(.top)
            
            Text("Get your API keys from the Blizzard Developer Portal")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    /// View shown when token fetch fails
    private var tokenErrorView: some View {
        VStack(spacing: 20) {
            Image(systemName: "xmark.circle")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("Authentication Failed")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Failed to authenticate with Blizzard API. Please check your Client ID and Secret in Settings.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Open Settings") {
                showingSettings = true
            }
            .buttonStyle(.borderedProminent)
            .padding(.top)
            
            Button("Try Again") {
                Task {
                    await fetchOAuthToken()
                }
            }
            .padding(.top, 5)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    /// Fetches an OAuth token using the stored credentials
    private func fetchOAuthToken() async {
        tokenStatus = .loading
        
        do {
            let token = try await OAuth.fetchToken(
                clientID: Secrets.clientID,
                clientSecret: Secrets.clientSecret
            )
            
            // Store the token
            Secrets.oauthToken = token.accessToken
            print("Successfully obtained OAuth token")
            tokenStatus = .success
        } catch {
            print("Failed to fetch OAuth token: \(error)")
            tokenStatus = .error
        }
    }
    
    /// Enum to track token status
    enum TokenStatus {
        case unknown
        case loading
        case success
        case error
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
