//
//  EventsView.swift
//  WoWBud
//
//  Created on 5/2/25.
//

import SwiftUI

// MARK: - Battleground Enum
private enum Battleground: String, CaseIterable {
    case wsg = "Warsong Gulch"
    case ab = "Arathi Basin"
    case av = "Alterac Valley"
}

// MARK: - Event Details Struct
/// Represents details about a specific event instance.
private struct WoWEventDetails {
    let name: String
    let startDate: Date
    let endDate: Date
    var isActive: Bool { Date() >= startDate && Date() < endDate }
}

// MARK: - Time Zone Helpers
private let realmTZ = TimeZone(identifier: "America/Denver")!  // MDT/MST
private let playerTZ = TimeZone(identifier: "America/Los_Angeles")!  // PDT/PST

/// Helper to create a Date object in a specific time zone.
/// Ensures the date components are correctly assigned.
private func date(
    _ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int, in timeZone: TimeZone
) -> Date {
    // Correctly assign components: year, month, day, hour, minute
    let components = DateComponents(
        timeZone: timeZone, year: year, month: month, day: day, hour: hour, minute: minute)
    // Use the system's current calendar to create the date from components
    guard let date = Calendar.current.date(from: components) else {
        // Fallback or error handling if date creation fails (should not happen with valid inputs)
        fatalError(
            "Failed to create date from components: Y\(year)-M\(month)-D\(day) H\(hour):M\(minute) in \(timeZone.identifier)"
        )
    }
    return date
}

extension Date {
    /// Converts the date to the equivalent moment in a different time zone.
    /// Note: This doesn't change the underlying timestamp, just how it's interpreted by Calendar.
    /// For calculations relative to a specific time zone's rules (like event start/end),
    /// ensure the reference Date object itself represents the correct instant.
    /// It's often better to perform date calculations *within* the target time zone's context.
    func convertToTimeZone(_ timeZone: TimeZone) -> Date {
        let calendar = Calendar.current
        let _ = calendar.dateComponents(in: timeZone, from: self)
        // We just need the components relative to the target zone for calculations
        // Reconstructing the date might not be necessary if using Calendar methods directly
        // For simplicity in the calculation function, we'll work with components or adjusted dates.
        // Let's refine the calculation function instead.
        return self  // Placeholder - actual conversion logic is integrated into calculation
    }
}

struct EventsView: View {
    // State for current time and timer
    @State private var currentTime = Date()
    @State private var timer: Timer? = nil

    // Date formatter
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
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

                // Current Battleground Weekend
                eventCardView(
                    title: "Battleground Weekend",
                    event: currentBattlegroundEvent,
                    iconName: "flag.2.crossed.fill",
                    iconColor: .red
                )

                // Double XP Event (Example - adjust logic as needed)
                eventCardView(
                    title: "Double Experience",
                    event: currentDoubleXPEvent,
                    iconName: "arrow.up.forward.circle.fill",
                    iconColor: .green
                )

                // Info block
                VStack(alignment: .leading, spacing: 8) {
                    Text("Event Information")
                        .font(.headline)

                    Text("• Battleground weekends grant bonus honor.")
                    Text("• Double XP events accelerate leveling.")
                    Text("• Check the in-game calendar for exact times.")
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
        .navigationTitle("Current Events")
        .onAppear {
            // Start timer to update current time
            timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in  // Update every minute
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

    /// View for displaying an event card
    private func eventCardView(
        title: String, event: WoWEventDetails?, iconName: String, iconColor: Color
    ) -> some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundColor(iconColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)

                    if let event = event {
                        Text(event.name)  // Display the specific event name
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("No active event")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Active/Inactive Badge
                if let event = event, event.isActive(relativeTo: currentTime) {  // Pass current time
                    Text("Active")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                } else {
                    Text("Inactive")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }

            Divider()

            // Time remaining or next start
            if let event = event {
                VStack(spacing: 4) {
                    if event.isActive(relativeTo: currentTime) {  // Pass current time
                        Text("Ends In")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        // Display end date using the formatter (which uses local time zone)
                        Text(dateFormatter.string(from: event.endDate))
                            .font(.callout)

                        let remainingTime = event.endDate.timeIntervalSince(currentTime)
                        if remainingTime > 0 {
                            Text(timeFormatter.string(from: remainingTime) ?? "")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(iconColor)
                        } else {
                            Text("Ending now")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.gray)
                        }
                    } else {
                        Text("Starts On")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        // Display start date using the formatter (which uses local time zone)
                        Text(dateFormatter.string(from: event.startDate))
                            .font(.callout)

                        let timeUntilStart = event.startDate.timeIntervalSince(currentTime)
                        if timeUntilStart > 0 {
                            Text(timeFormatter.string(from: timeUntilStart) ?? "")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(iconColor.opacity(0.7))  // Dimmed color for upcoming
                        } else {
                            // This case might occur briefly if the timer hasn't fired exactly at the start time
                            Text("Starting now")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.gray)
                        }
                    }
                }
            } else {
                Text("No event scheduled currently.")  // Updated message for blank weekends
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
    }

    // MARK: - Event Logic

    /// Calculates the current or next Battleground Holiday based on the 6-week cycle.
    /// Performs calculations relative to the Realm Time Zone (MDT/MST).
    /// Cycle: WSG -> Blank -> AB -> Blank -> AV -> Blank
    /// - Parameter referenceDate: The date/time to check against (usually the current time).
    /// - Returns: A `WoWEventDetails` object for the active or next upcoming BG holiday.
    private func calculateCurrentBGHoliday(at referenceDate: Date) -> WoWEventDetails? {
        var realmCalendar = Calendar.current  // Use user's locale, but fix the time zone
        realmCalendar.timeZone = realmTZ

        // Anchor date: Known start of a WSG weekend in the cycle (Friday 00:01 Realm Time)
        // Adjusted anchor to April 4, 2025, so that May 2, 2025 falls into the AV week (Week 4).
        let cycleAnchorDate = date(2025, 4, 4, 0, 1, in: realmTZ)
        let cycleLengthWeeks = 6
        let eventDurationSeconds: TimeInterval = 4 * 24 * 60 * 60  // 4 days

        // Calculate the difference in weeks between the anchor and the reference date
        // Using weekOfYear calculation which might be sensitive near year boundaries,
        // but should be stable for intra-year calculations far from the boundary.
        // Consider using a more robust method like days/7 if issues arise.
        guard
            let weeksSinceAnchor = realmCalendar.dateComponents(
                [.weekOfYear], from: cycleAnchorDate, to: referenceDate
            ).weekOfYear
        else {
            print("Error calculating weeks since anchor.")
            return nil  // Should not happen with valid dates
        }

        // Determine the start date of the *cycle instance* containing the reference date.
        // This is the date of the WSG week (Week 0) for the current 6-week block.
        let cycleInstanceNumber = floor(Double(weeksSinceAnchor) / Double(cycleLengthWeeks))
        guard
            let cycleInstanceStartDate = realmCalendar.date(
                byAdding: .weekOfYear, value: Int(cycleInstanceNumber) * cycleLengthWeeks,
                to: cycleAnchorDate)
        else {
            print("Error calculating cycle instance start date.")
            return nil
        }

        // Find the week number within the 6-week cycle (0 to 5) relative to the cycle instance start.
        // Use day difference for more reliable week calculation within the cycle.
        guard
            let daysSinceCycleInstanceStart = realmCalendar.dateComponents(
                [.day], from: cycleInstanceStartDate, to: referenceDate
            ).day
        else {
            print("Error calculating days since cycle instance start.")
            return nil
        }
        // Week number within the cycle (0-5). Integer division of days by 7.
        // Ensure result is non-negative before division.
        let currentWeekInCycle = max(0, daysSinceCycleInstanceStart) / 7

        // --- Check for currently active event ---
        var activeBG: Battleground?
        var eventStartDateForActiveCheck: Date?

        // Determine the potential active BG and its theoretical start date based on the week in the cycle.
        switch currentWeekInCycle {
        case 0:  // WSG week (Week 0)
            activeBG = .wsg
            // WSG starts at the beginning of the cycle instance.
            eventStartDateForActiveCheck = cycleInstanceStartDate
        case 2:  // AB week (Week 2)
            activeBG = .ab
            // AB starts 2 weeks after the beginning of the cycle instance.
            eventStartDateForActiveCheck = realmCalendar.date(
                byAdding: .weekOfYear, value: 2, to: cycleInstanceStartDate)
        case 4:  // AV week (Week 4)
            activeBG = .av
            // AV starts 4 weeks after the beginning of the cycle instance.
            eventStartDateForActiveCheck = realmCalendar.date(
                byAdding: .weekOfYear, value: 4, to: cycleInstanceStartDate)
        default:  // Blank week (Weeks 1, 3, 5)
            activeBG = nil
        }

        // If a BG is scheduled for this week, check if the referenceDate falls within its 4-day window.
        if let bg = activeBG, let startDate = eventStartDateForActiveCheck {
            // Ensure startDate calculation was successful
            let eventWindow = DateInterval(start: startDate, duration: eventDurationSeconds)
            if eventWindow.contains(referenceDate) {
                // Found active event
                return WoWEventDetails(
                    name: bg.rawValue + " Weekend",
                    startDate: eventWindow.start,
                    endDate: eventWindow.end)
            }
        }

        // --- No active event, find the next upcoming one ---

        // Determine the start date of the *next* cycle instance if needed.
        guard
            let nextCycleInstanceStartDate = realmCalendar.date(
                byAdding: .weekOfYear, value: cycleLengthWeeks, to: cycleInstanceStartDate)
        else {
            print("Error calculating next cycle instance start date.")
            return nil
        }

        // Find the next non-blank week (0, 2, or 4) starting from the current week.
        var nextEventStartDate: Date?
        var nextBG: Battleground?

        for weekOffset in 0..<cycleLengthWeeks {
            // Calculate the week number in the cycle we are checking
            let potentialNextWeekIndex = currentWeekInCycle + 1 + weekOffset
            let potentialNextWeekInCycle = potentialNextWeekIndex % cycleLengthWeeks
            // Determine if this potential week falls into the next cycle instance
            let isNextCycle = potentialNextWeekIndex >= cycleLengthWeeks
            let relevantCycleStartDate =
                isNextCycle ? nextCycleInstanceStartDate : cycleInstanceStartDate

            var potentialStartDate: Date?
            var potentialBG: Battleground?

            switch potentialNextWeekInCycle {
            case 0:  // WSG
                potentialBG = .wsg
                potentialStartDate = relevantCycleStartDate  // Starts at the beginning of its cycle
            case 2:  // AB
                potentialBG = .ab
                potentialStartDate = realmCalendar.date(
                    byAdding: .weekOfYear, value: 2, to: relevantCycleStartDate)
            case 4:  // AV
                potentialBG = .av
                potentialStartDate = realmCalendar.date(
                    byAdding: .weekOfYear, value: 4, to: relevantCycleStartDate)
            default:  // Blank week
                potentialBG = nil
            }

            // If we found a non-blank week and its start date is after the reference date, this is our next event.
            if let bg = potentialBG, let startDate = potentialStartDate, startDate > referenceDate {
                nextEventStartDate = startDate
                nextBG = bg  // Assign the correct BG
                break  // Exit the loop once the immediate next event is found
            }
        }

        // Ensure we found a next event by checking the optional variables populated in the loop
        guard let finalNextStartDate = nextEventStartDate, let finalNextBG = nextBG else {
            // If the loop completes without finding a future event (should be logically impossible with a cycle), print an error.
            print("Error: Could not determine the next upcoming BG event.")
            // Attempt to return the start of the *next* cycle's WSG as a fallback.
            // `nextCycleInstanceStartDate` is guaranteed non-nil here due to the earlier guard let.
            // No need for `if let` binding.
            let fallbackDate = nextCycleInstanceStartDate
            return WoWEventDetails(
                name: Battleground.wsg.rawValue + " Weekend",
                startDate: fallbackDate,
                endDate: fallbackDate.addingTimeInterval(eventDurationSeconds))
            // If even that fails (which it shouldn't), return nil.
            // return nil // This line is now unreachable due to the return above, but kept for clarity of intent.
        }

        // Calculate the end date for the found upcoming event.
        let nextEventEndDate = finalNextStartDate.addingTimeInterval(eventDurationSeconds)

        // Return the details of the next upcoming event.
        return WoWEventDetails(
            name: finalNextBG.rawValue + " Weekend",
            startDate: finalNextStartDate,
            endDate: nextEventEndDate)
    }

    /// Provides the currently active or next upcoming Battleground event details.
    private var currentBattlegroundEvent: WoWEventDetails? {
        return calculateCurrentBGHoliday(at: currentTime)
    }

    /// Determines the current or next Double XP event (Example: First weekend of the month).
    /// NOTE: This logic remains unchanged from the original, using local time assumptions.
    /// It might need similar realm-time adjustments if XP events follow server time.
    private var currentDoubleXPEvent: WoWEventDetails? {
        let calendar = Calendar.current  // Uses local time zone by default
        let now = currentTime

        // Find the start of the current month
        guard
            let startOfMonth = calendar.date(
                from: calendar.dateComponents([.year, .month], from: now))
        else { return nil }

        // Find the first Friday of the month
        var firstFridayComponents = calendar.dateComponents([.year, .month], from: startOfMonth)
        firstFridayComponents.weekday = 6  // Friday
        firstFridayComponents.weekdayOrdinal = 1  // First Friday
        guard
            let firstFriday = calendar.nextDate(
                after: startOfMonth, matching: firstFridayComponents, matchingPolicy: .nextTime),
            // Assuming XP event starts 5 PM *local time* based on original code
            let friday5PM = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: firstFriday)
        else { return nil }

        // Calculate end date (Monday 10 AM *local time*)
        guard let followingMonday = calendar.date(byAdding: .day, value: 3, to: firstFriday),
            // Assuming XP event ends 10 AM *local time*
            let monday10AM = calendar.date(
                bySettingHour: 10, minute: 0, second: 0, of: followingMonday)
        else { return nil }

        let eventName = "Double XP Weekend"
        let eventDetails = WoWEventDetails(
            name: eventName, startDate: friday5PM, endDate: monday10AM)

        // Check if 'now' falls within this month's event window
        if now >= friday5PM && now < monday10AM {
            return eventDetails  // Active
        } else if now < friday5PM {
            return eventDetails  // Upcoming this month
        } else {
            // If it's after this month's event, calculate next month's event
            guard let nextMonthStart = calendar.date(byAdding: .month, value: 1, to: startOfMonth)
            else { return nil }
            var nextMonthFridayComponents = calendar.dateComponents(
                [.year, .month], from: nextMonthStart)
            nextMonthFridayComponents.weekday = 6  // Friday
            nextMonthFridayComponents.weekdayOrdinal = 1  // First Friday
            guard
                let nextFirstFriday = calendar.nextDate(
                    after: nextMonthStart, matching: nextMonthFridayComponents,
                    matchingPolicy: .nextTime),
                let nextFriday5PM = calendar.date(
                    bySettingHour: 17, minute: 0, second: 0, of: nextFirstFriday),
                let nextFollowingMonday = calendar.date(
                    byAdding: .day, value: 3, to: nextFirstFriday),
                let nextMonday10AM = calendar.date(
                    bySettingHour: 10, minute: 0, second: 0, of: nextFollowingMonday)
            else { return nil }

            return WoWEventDetails(
                name: eventName, startDate: nextFriday5PM, endDate: nextMonday10AM)  // Upcoming next month
        }
    }
}

// Add isActive check relative to a specific time
extension WoWEventDetails {
    func isActive(relativeTo date: Date) -> Bool {
        return date >= startDate && date < endDate
    }
}

struct EventsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            EventsView()
        }
    }
}
