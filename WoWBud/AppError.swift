//
//  AppError.swift
//  WoWClassicBuilder
//
//  Swift 6 – existential `any` applied
//

import Foundation

/// Unified error funnel with provenance codes for telemetry.
/// Conforms to `Sendable` for cross-actor propagation.
enum AppError: Error, LocalizedError, Sendable {
    // Networking
    case invalidURL(String)
    case networkFailure(underlying: any Error)
    case badStatus(code: Int)
    case decodingFailure(entity: String, underlying: any Error)

    // Database
    case sql(String)
    case missingField(String)

    // Authentication
    case oauth(String)

    // General
    case unknown(any Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL(let url): return "Malformed URL: \(url)"
        case .networkFailure(let err): return err.localizedDescription
        case .badStatus(let code): return "HTTP status \(code)"
        case .decodingFailure(let who, let err):
            return "Decoding \(who) failed – \(err.localizedDescription)"
        case .sql(let msg): return "SQLite error: \(msg)"
        case .missingField(let f): return "Missing \(f) in data"
        case .oauth(let msg): return "OAuth flow failed: \(msg)"
        case .unknown(let err): return "An unexpected error occurred: \(err.localizedDescription)"
        }
    }
}
