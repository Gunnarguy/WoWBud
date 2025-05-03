//
//  ResetSchedule.swift
//

import Foundation

enum Region: Sendable { case us, eu }

struct ResetSchedule: Sendable {

    // Use UTC calendar for consistency
    private static let calendarUTC: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!  // Explicitly set UTC
        return calendar
    }()

    /// Next weekly reset date (UTC)
    /// Calculates the next reset time based on the region.
    /// US resets Tuesday 15:00 UTC (8:00 PDT / 9:00 MDT).
    /// EU resets Wednesday 07:00 UTC (8:00 CET / 9:00 CEST).
    static func next(for region: Region, from now: Date = .init()) -> Date {
        var comps = DateComponents()
        // Set common components
        comps.minute = 0
        comps.second = 0

        switch region {
        case .us:
            comps.weekday = 3  // Tuesday
            comps.hour = 15  // 15:00 UTC
        case .eu:
            comps.weekday = 4  // Wednesday
            comps.hour = 7  // 07:00 UTC (Corrected from 4)
        }

        // Find the next matching date after the current time
        return calendarUTC.nextDate(
            after: now,
            matching: comps,
            matchingPolicy: .nextTime)!
    }
}
