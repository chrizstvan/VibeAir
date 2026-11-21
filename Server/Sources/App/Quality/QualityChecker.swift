//
//  File.swift
//  Server
//
//  Created by Christian Stevanus on 21/11/26.
//

import Foundation

enum Quality: String {
    case ok, stale, frozen
}

struct QualityRules {
    let staleAfter: [String: TimeInterval]   // each source, every second
    let frozenAfterHours: Int

    static let current = QualityRules(
        staleAfter: ["waqi": 3.0 * 3600, "airgradient": 3600],
        frozenAfterHours: 12
    )
}

enum QualityChecker {
    /// previousValues: Hourly PM2.5 values from previous hours for the same station,
    /// one value per `measured_at`, ordered from newest to oldest.
    static func check(
        _ observation: Observation,
        fetchedAt: Date,
        previousValues: [Double],
        rules: QualityRules = .current
    ) -> Quality {
        let age = fetchedAt.timeIntervalSince(observation.measuredAt)
        if let limit = rules.staleAfter[observation.sourceID], age > limit {
            return .stale
        }
        let needed = rules.frozenAfterHours - 1
        if previousValues.count >= needed,
           previousValues.prefix(needed).allSatisfy({ $0 == observation.pm25 }) {
            return .frozen
        }
        return .ok
    }
}
