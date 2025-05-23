//
//  ResetTimerView.swift
//  WoWBud
//
//  Created on 4/30/25.
//

import SwiftUI

struct ResetTimerView: View {
    // Selected region
    @State private var selectedRegion: Region = .us

    // Current time
    @State private var currentTime = Date()

    // Timer for keeping the view updated
    @State private var timer: Timer? = nil

    // Date formatter
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    // Time formatter (for remaining time)
    private let timeFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute]
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 3
        return formatter
    }()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Region selector
                Picker("Region", selection: $selectedRegion) {
                    Text("Americas").tag(Region.us)
                    Text("Europe").tag(Region.eu)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Header with current time
                VStack(spacing: 4) {
                    Text("Current Time")
                        .font(.headline)

                    Text(dateFormatter.string(from: currentTime))
                        .font(.subheadline)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                .padding(.horizontal)

                // Weekly raid reset
                resetCardView(
                    title: "Weekly Reset",
                    subtitle: "All raid lockouts, weekly quests",
                    resetDate: weeklyResetDate,
                    iconName: "arrow.clockwise"
                )

                // Molten Core / Onyxia timer
                // These have a special opening date for the Anniversary servers
                let moltenCoreOpenDate = openingDateFor(raid: .moltenCore)
                if currentTime < moltenCoreOpenDate {
                    // Show countdown to opening
                    countdownCardView(
                        title: "Molten Core & Onyxia",
                        subtitle: "Anniversary Classic Phase 2",
                        targetDate: moltenCoreOpenDate,
                        iconName: "flame.fill"
                    )
                } else {
                    // Show reset timer
                    resetCardView(
                        title: "Molten Core & Onyxia",
                        subtitle: "Raid ID reset",
                        resetDate: nextRaidResetDate(for: .moltenCore),
                        iconName: "flame.fill"
                    )
                }

                // Blackwing Lair timer
                let bwlOpenDate = openingDateFor(raid: .blackwingLair)
                if currentTime < bwlOpenDate {
                    // Show countdown to opening
                    countdownCardView(
                        title: "Blackwing Lair",
                        subtitle: "Anniversary Classic Phase 3",
                        targetDate: bwlOpenDate,
                        iconName: "dragon"
                    )
                } else {
                    // Show reset timer
                    resetCardView(
                        title: "Blackwing Lair",
                        subtitle: "Raid ID reset",
                        resetDate: nextRaidResetDate(for: .blackwingLair),
                        iconName: "dragon"
                    )
                }

                // ZG timer
                let zgOpenDate = openingDateFor(raid: .zulGurub)
                if currentTime < zgOpenDate {
                    // Show countdown to opening
                    countdownCardView(
                        title: "Zul'Gurub",
                        subtitle: "Anniversary Classic Phase 4",
                        targetDate: zgOpenDate,
                        iconName: "timer"
                    )
                } else {
                    // Show reset timer (ZG has a 3-day reset)
                    resetCardView(
                        title: "Zul'Gurub",
                        subtitle: "Raid ID reset (3-day)",
                        resetDate: nextRaidResetDate(for: .zulGurub),
                        iconName: "timer"
                    )
                }

                // AQ timer
                let aqOpenDate = openingDateFor(raid: .ahnQiraj)
                if currentTime < aqOpenDate {
                    // Show countdown to opening
                    countdownCardView(
                        title: "Ahn'Qiraj Temples",
                        subtitle: "Anniversary Classic Phase 5",
                        targetDate: aqOpenDate,
                        iconName: "ant"
                    )
                } else {
                    // Show reset timer
                    resetCardView(
                        title: "Ahn'Qiraj Temples",
                        subtitle: "Raid ID reset",
                        resetDate: nextRaidResetDate(for: .ahnQiraj),
                        iconName: "ant"
                    )
                }

                // Naxx timer
                let naxxOpenDate = openingDateFor(raid: .naxxramas)
                if currentTime < naxxOpenDate {
                    // Show countdown to opening
                    countdownCardView(
                        title: "Naxxramas",
                        subtitle: "Anniversary Classic Phase 6",
                        targetDate: naxxOpenDate,
                        iconName: "staroflife"
                    )
                } else {
                    // Show reset timer
                    resetCardView(
                        title: "Naxxramas",
                        subtitle: "Raid ID reset",
                        resetDate: nextRaidResetDate(for: .naxxramas),
                        iconName: "staroflife"
                    )
                }

                // TBC countdown
                let tbcDate = openingDateFor(raid: .burningCrusade)
                if currentTime < tbcDate {
                    // Show countdown to opening
                    countdownCardView(
                        title: "The Burning Crusade",
                        subtitle: "Anniversary Classic Progression",
                        targetDate: tbcDate,
                        iconName: "portal"
                    )
                }

                // Info block
                VStack(alignment: .leading, spacing: 8) {
                    Text("Anniversary Server Info")
                        .font(.headline)

                    Text("• Fresh servers launched: Nov 21, 2024")
                    Text("• Weekly reset: \(selectedRegion == .us ? "Tuesday" : "Wednesday")")
                    Text("• Hardcore characters remain in Classic Era")
                    Text("• Features dual spec, removed buff limits")
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                .padding(.horizontal)

                // Attribution
                Text("Data for WoW Classic 20th Anniversary")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top)
            }
            .padding(.vertical)
        }
        .navigationTitle("Classic Reset Timers")
        .onAppear {
            // Start timer to update current time
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                currentTime = Date()
            }
        }
        .onDisappear {
            // Clean up timer
            timer?.invalidate()
            timer = nil
        }
    }

    // MARK: - Subviews

    /// View for displaying a reset timer card
    private func resetCardView(title: String, subtitle: String, resetDate: Date, iconName: String)
        -> some View
    {
        VStack(spacing: 12) {
            // Header
            HStack {
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundColor(.blue)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            Divider()

            // Time remaining
            VStack(spacing: 4) {
                Text("Next Reset")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(dateFormatter.string(from: resetDate))
                    .font(.callout)

                let remainingTime = resetDate.timeIntervalSince(currentTime)
                if remainingTime > 0 {
                    Text(timeFormatter.string(from: remainingTime) ?? "")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                } else {
                    Text("Resetting now")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
    }

    /// View for displaying a countdown to raid opening
    private func countdownCardView(
        title: String, subtitle: String, targetDate: Date, iconName: String
    ) -> some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundColor(.orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Badge for "coming soon"
                Text("Coming Soon")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }

            Divider()

            // Time until opening
            VStack(spacing: 4) {
                Text("Opens On")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(dateFormatter.string(from: targetDate))
                    .font(.callout)

                let remainingTime = targetDate.timeIntervalSince(currentTime)
                if remainingTime > 0 {
                    Text(timeFormatter.string(from: remainingTime) ?? "")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                } else {
                    Text("Opening now")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
    }

    // MARK: - Helper functions

    /// Get the next weekly reset date based on the selected region.
    /// Uses UTC times: US Tuesday 15:00, EU Wednesday 07:00.
    private var weeklyResetDate: Date {
        // Use the centralized ResetSchedule logic
        return ResetSchedule.next(for: selectedRegion, from: currentTime)

        /* // Original logic kept for reference, now uses ResetSchedule.next
        let calendar = Calendar.current // Uses local time zone implicitly
        
        // Get current components in local time zone
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second, .timeZone], from: currentTime)
        
        // Set time to reset time in UTC
        // US: 15:00 UTC (e.g., 8am PDT, 9am MDT)
        // EU: 07:00 UTC (e.g., 8am CET, 9am CEST)
        components.hour = selectedRegion == .us ? 15 : 7
        components.minute = 0
        components.second = 0
        components.timeZone = TimeZone(secondsFromGMT: 0) // Specify UTC for these components
        
        // Set weekday to reset day (Tuesday for US, Wednesday for EU)
        components.weekday = selectedRegion == .us ? 3 : 4 // 3 = Tuesday, 4 = Wednesday
        
        // We need to find the *next* occurrence in the *UTC* calendar
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(secondsFromGMT: 0)!
        
        // Get the date of the reset using the UTC calendar and components
        let resetDate = utcCalendar.nextDate(
            after: currentTime, // Find next occurrence after current time
            matching: components,
            matchingPolicy: .nextTime // Find the very next time match
        ) ?? currentTime // Fallback to current time if calculation fails
        
        return resetDate
        */
    }

    /// Get the next reset date for a specific raid
    private func nextRaidResetDate(for raid: Raid) -> Date {
        switch raid {
        case .zulGurub:
            // ZG resets every 3 days
            return getNextIntervalReset(days: 3)
        default:
            // All other raids reset weekly
            return weeklyResetDate
        }
    }

    /// Get reset date for a specific interval (e.g., 3 days for ZG).
    /// Uses a reference date and calculates forward based on UTC reset times.
    private func getNextIntervalReset(days: Int) -> Date {
        // Use UTC calendar for consistency
        var calendarUTC = Calendar(identifier: .gregorian)
        calendarUTC.timeZone = TimeZone(secondsFromGMT: 0)!

        // Get reference reset date (first reset was Nov 21, 2024 at reset time)
        // Use UTC components for the reference date
        let referenceComponents = DateComponents(
            timeZone: TimeZone(secondsFromGMT: 0),  // Specify UTC
            year: 2024,
            month: 11,
            day: 21,  // Thursday - This might need adjustment if the *first* reset wasn't on launch day
            hour: selectedRegion == .us ? 15 : 7,  // Use correct UTC reset hour
            minute: 0,
            second: 0
        )

        // Ensure reference date is calculated correctly in UTC
        guard let referenceDate = calendarUTC.date(from: referenceComponents) else {
            return currentTime  // Fallback
        }

        // Calculate the time elapsed since the reference date in UTC
        let timeSinceReference = currentTime.timeIntervalSince(referenceDate)

        // If the current time is before the reference date, return the reference date
        if timeSinceReference < 0 {
            return referenceDate
        }

        // Calculate the number of full intervals passed
        let intervalSeconds = Double(days * 24 * 60 * 60)
        let intervalsPassed = floor(timeSinceReference / intervalSeconds)

        // Calculate the date of the next reset by adding intervals to the reference date
        let nextResetDate = referenceDate.addingTimeInterval(
            (intervalsPassed + 1) * intervalSeconds)

        return nextResetDate
    }

    /// Get opening date for a raid based on Anniversary schedule.
    /// Uses UTC reset times for consistency.
    private func openingDateFor(raid: Raid) -> Date {
        // Use UTC calendar for consistency
        var calendarUTC = Calendar(identifier: .gregorian)
        calendarUTC.timeZone = TimeZone(secondsFromGMT: 0)!

        var dateComponents = DateComponents()
        // Set components in UTC
        dateComponents.timeZone = TimeZone(secondsFromGMT: 0)
        dateComponents.hour = selectedRegion == .us ? 15 : 7  // Reset time in UTC
        dateComponents.minute = 0
        dateComponents.second = 0

        switch raid {
        case .moltenCore:
            // Phase 2 - December 12, 2024
            dateComponents.year = 2024
            dateComponents.month = 12
            dateComponents.day = 12
        case .blackwingLair:
            // Phase 3 - February 13, 2025
            dateComponents.year = 2025
            dateComponents.month = 2
            dateComponents.day = 13
        case .zulGurub:
            // Phase 4 - April 10, 2025
            dateComponents.year = 2025
            dateComponents.month = 4
            dateComponents.day = 10
        case .ahnQiraj:
            // Phase 5 - July 24, 2025
            dateComponents.year = 2025
            dateComponents.month = 7
            dateComponents.day = 24
        case .naxxramas:
            // Phase 6 - October 23, 2025
            dateComponents.year = 2025
            dateComponents.month = 10
            dateComponents.day = 23
        case .burningCrusade:
            // Expected early 2026
            dateComponents.year = 2026
            dateComponents.month = 1
            dateComponents.day = 29
        }

        return calendarUTC.date(from: dateComponents) ?? currentTime
    }
}

// MARK: - Models

/// Enum for raid types
enum Raid {
    case moltenCore
    case blackwingLair
    case zulGurub
    case ahnQiraj
    case naxxramas
    case burningCrusade
}

struct ResetTimerView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ResetTimerView()
        }
    }
}
