//
//  WoWBudApp.swift
//  WoWBud
//
//  Created by Gunnar Hostetler on 4/30/25.
//

import SwiftUI

@main
struct WoWBudApp: App {
    // App version and brand info
    private let appVersion = "1.0.0"
    private let appName = "WoWBud Classic Anniversary"
    
    // App state
    @State private var isFirstLaunch = UserDefaults.standard.object(forKey: "hasLaunchedBefore") == nil
    @State private var showingSplash = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // Main content
                NavigationView {
                    ContentView()
                }
                
                // Splash screen (only on first launch or during loading)
                if showingSplash {
                    splashScreen
                }
            }
            .onAppear {
                // Check if this is the first launch
                if isFirstLaunch {
                    // Mark as launched
                    UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
                    
                    // Show splash screen for longer on first launch
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation {
                            showingSplash = false
                        }
                    }
                } else {
                    // Quick splash for returning users
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        withAnimation {
                            showingSplash = false
                        }
                    }
                }
                
                // Initialize OAuth token if credentials exist
                if Secrets.clientID != "<INSERT-CLIENT-ID>" &&
                   Secrets.clientSecret != "<INSERT-CLIENT-SECRET>" &&
                   Secrets.oauthToken.isEmpty {
                    refreshOAuthToken()
                }
            }
        }
    }
    
    /// Splash screen view
    private var splashScreen: some View {
        ZStack {
            // Background color
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                // App logo/icon
                Image(systemName: "shield.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.yellow)
                
                // App name
                Text(appName)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                // Anniversary edition badge
                Text("20th Anniversary Edition")
                    .font(.headline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.yellow)
                    .foregroundColor(.black)
                    .cornerRadius(20)
                
                // Loading indicator
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .padding(.top, 30)
                
                // Version
                Text("Version \(appVersion)")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.top, 10)
            }
        }
        .transition(.opacity)
    }
    
    /// Refresh the OAuth token
    private func refreshOAuthToken() {
        Task {
            do {
                let token = try await OAuth.fetchToken(
                    clientID: Secrets.clientID,
                    clientSecret: Secrets.clientSecret
                )
                
                // Store the token
                Secrets.oauthToken = token
                print("Successfully obtained OAuth token")
            } catch {
                print("Failed to fetch OAuth token: \(error)")
            }
        }
    }
}
