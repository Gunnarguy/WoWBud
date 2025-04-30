//
//  ResetSchedule.swift
//

import Foundation

enum Region: Sendable { case us, eu }

struct ResetSchedule: Sendable {

    private static let calendarUTC = Calendar(identifier: .gregorian)

    /// Next weekly reset date (UTC)
    static func next(for region: Region, from now: Date = .init()) -> Date {
        var comps = DateComponents()
        switch region {
        case .us:
            comps.weekday = 3   // Tuesday
            comps.hour    = 15  // 15:00 UTC
        case .eu:
            comps.weekday = 4   // Wednesday
            comps.hour    = 4
        }
        comps.minute = 0; comps.second = 0
        return calendarUTC.nextDate(after: now,
                                    matching: comps,
                                    matchingPolicy: .nextTime)!
    }
}
