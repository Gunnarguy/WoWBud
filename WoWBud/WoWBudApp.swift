//
//  WoWBudApp.swift
//  WoWBud
//
//  Created by Gunnar Hostetler on 4/30/25.
//

import SwiftUI

@main
struct WoWBudApp: App {
    // State to control the presentation of the settings sheet
    @State private var showingSettings = false

    var body: some Scene {
        WindowGroup {
            // Main application view
            NavigationView {  // Use NavigationView for title and potential toolbar items
                mainContentView
            }
            // Present the SettingsView as a sheet if needed
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            // Check credentials when the view appears
            .onAppear(perform: checkCredentials)
        }
    }

    /// Determines the main content view based on whether credentials are set.
    @ViewBuilder
    private var mainContentView: some View {
        // Check if essential credentials are placeholders
        if Secrets.clientID == "<INSERT-CLIENT-ID>"
            || Secrets.clientSecret == "<INSERT-CLIENT-SECRET>"
        {
            // Show a message prompting the user to enter settings
            VStack {
                Text("API Credentials Needed")
                    .font(.headline)
                Text("Please enter your Blizzard API Client ID and Secret in Settings.")
                    .multilineTextAlignment(.center)
                    .padding()
                Button("Open Settings") {
                    showingSettings = true
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        } else {
            // If credentials seem okay, show the main lookup view
            SpellLookupView()  // Use the dedicated view for spell lookup
        }
    }

    /// Checks if credentials are set and presents the settings sheet if not.
    private func checkCredentials() {
        // Present settings immediately if placeholders are detected
        if Secrets.clientID == "<INSERT-CLIENT-ID>"
            || Secrets.clientSecret == "<INSERT-CLIENT-SECRET>"
        {
            showingSettings = true
        }
        // TODO: Add logic here later to fetch/validate OAuth token if needed
    }
}
