import SwiftUI

/// View for entering and saving Blizzard API credentials.
struct SettingsView: View {
    // State variables bound to text fields
    @State private var clientID: String = Secrets.clientID  // Load existing or placeholder
    @State private var clientSecret: String = Secrets.clientSecret  // Load existing or placeholder
    @State private var saveMessage: String? = nil  // Feedback message

    // Environment variable to dismiss the view
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section("API Credentials") {
                    // Text field for Client ID
                    TextField("Client ID", text: $clientID)
                        .textContentType(.username)  // Helps with autofill hints
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)  // Correct modifier name

                    // Secure field for Client Secret
                    SecureField("Client Secret", text: $clientSecret)
                        .textContentType(.password)  // Helps with autofill hints
                }

                Section {
                    // Button to save the credentials
                    Button("Save Credentials") {
                        saveCredentials()
                    }
                }

                // Display feedback message if available
                if let message = saveMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(message.contains("Error") ? .red : .green)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                // Add a Done button to dismiss the view
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    /// Saves the entered credentials to the Keychain.
    private func saveCredentials() {
        // Basic validation
        guard !clientID.isEmpty, !clientSecret.isEmpty else {
            saveMessage = "Error: Both fields are required."
            return
        }

        // Attempt to store using Secrets helper
        let idSuccess = Secrets.store("wow_client_id", value: clientID)
        let secretSuccess = Secrets.store("wow_client_secret", value: clientSecret)

        if idSuccess && secretSuccess {
            saveMessage = "Credentials saved successfully!"
            // Optionally clear the OAuth token if credentials change
            Secrets.oauthToken = ""
            // Dismiss after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dismiss()
            }
        } else {
            saveMessage = "Error: Failed to save credentials to Keychain."
        }
    }
}

#Preview {
    SettingsView()
}
