import SwiftUI

/// View for looking up spell details by ID.
struct SpellLookupView: View {
    // State for the input spell ID
    @State private var spellID: String = ""
    // State to hold the fetched spell data
    @State private var spell: Spell? = nil
    // State for displaying error messages
    @State private var errorMessage: String? = nil
    // State to indicate loading activity
    @State private var isLoading: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Input field and fetch button
            HStack {
                TextField("Enter Spell ID", text: $spellID)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {  // Allow fetching on submit (e.g., pressing Enter)
                        Task { await fetchSpell() }
                    }

                // Fetch button with loading indicator
                Button {
                    Task { await fetchSpell() }
                } label: {
                    if isLoading {
                        ProgressView()  // Show spinner when loading
                            .frame(width: 44, height: 22)  // Match button size roughly
                    } else {
                        Text("Fetch")
                    }
                }
                .disabled(isLoading || spellID.isEmpty)  // Disable if loading or no ID
            }

            // Display area for fetched spell, error, or prompt
            Group {
                if let spell = spell {
                    // Display spell details
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name: \(spell.name)")
                            .font(.headline)
                        if let desc = spell.description {
                            Text("Description: \(desc)")
                                .font(.subheadline)
                                .lineLimit(nil)  // Allow multiple lines
                        }
                        // Display coefficient if available
                        if let coeff = spell.baseCoefficient, coeff != 0 {  // Only show if non-zero
                            Text(String(format: "Base Coefficient: %.3f", coeff))
                                .font(.footnote)
                        } else if spell.baseCoefficient == 0 {
                            Text("Base Coefficient: 0 (or N/A)")  // Indicate zero/missing
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                } else if let errorMessage = errorMessage {
                    // Display error message
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.callout)
                } else {
                    // Initial prompt message
                    Text("Enter a valid spell ID and tap Fetch.")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top)  // Add some space above the results

            Spacer()  // Push content to the top
        }
        .padding()  // Padding around the VStack
        .navigationTitle("WoW Spell Lookup")  // Title for the NavigationView
    }

    /// Fetches spell data using the DataBridge.
    private func fetchSpell() async {
        // Hide keyboard
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

        // Reset state before fetching
        errorMessage = nil
        spell = nil
        isLoading = true  // Start loading indicator

        // Ensure the ID is a valid integer
        guard let id = Int(spellID) else {
            errorMessage = "Invalid Spell ID format."
            isLoading = false  // Stop loading
            return
        }

        // Use DataBridge to fetch and potentially merge data
        do {
            // Assuming DataBridge handles fetching from API and local DB
            // We might need to adjust this if DataBridge isn't set up yet
            // For now, directly call services as before, but ideally use DataBridge
            var fetchedSpell = try await BlizzardAPIService().spell(id: id)

            // Check local DB only if API didn't provide a coefficient
            if fetchedSpell.baseCoefficient == nil {
                let localCoeff = try await ClassicDBService.shared.spellBonusCoefficient(id: id)
                // Only assign if local DB had a non-zero value
                if localCoeff != 0 {
                    fetchedSpell.baseCoefficient = localCoeff
                }
            }

            // Update the state with the fetched spell
            self.spell = fetchedSpell
        } catch let error as AppError {
            // Handle specific AppErrors
            errorMessage = "Error: \(error.localizedDescription)"
        } catch {
            // Handle generic errors
            errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
        }

        isLoading = false  // Stop loading indicator
    }
}

#Preview {
    NavigationView {  // Wrap in NavigationView for preview title
        SpellLookupView()
    }
}