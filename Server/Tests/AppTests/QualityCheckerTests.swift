//
//  File.swift
//  Server
//
//  Created by Christian Stevanus on 21/11/26.
//

import Testing
import Foundation
import AirCore
@testable import App

private let now = Date(timeIntervalSince1970: 1_793_000_000)

private func observation(source: String, ageHours: Double, pm25: Double) -> Observation {
    Observation(
        sourceID: source, externalID: "test", name: nil, owner: nil,
        coordinate: Coordinate(latitude: -6.2, longitude: 106.8),
        kind: .unknown,
        measuredAt: now.addingTimeInterval(-ageHours * 3600),
        pm25: pm25, aqiReported: nil, humidity: nil
    )
}

@Test func freshMovingReadingIsOK() {
    let result = QualityChecker.check(observation(source: "waqi", ageHours: 1.1, pm25: 40),
                                      fetchedAt: now, previousValues: [38, 41, 45])
    #expect(result == .ok)
}

@Test func staleThresholdDependsOnSource() {
    #expect(QualityChecker.check(observation(source: "waqi", ageHours: 1.5, pm25: 40),
                                 fetchedAt: now, previousValues: []) == .ok)
    #expect(QualityChecker.check(observation(source: "airgradient", ageHours: 1.5, pm25: 40),
                                 fetchedAt: now, previousValues: []) == .stale)
    #expect(QualityChecker.check(observation(source: "waqi", ageHours: 3.5, pm25: 40),
                                 fetchedAt: now, previousValues: []) == .stale)
}

@Test func twelveIdenticalHoursIsFrozen() {
    let same = Array(repeating: 33.0, count: 11)
    #expect(QualityChecker.check(observation(source: "waqi", ageHours: 1.1, pm25: 33),
                                 fetchedAt: now, previousValues: same) == .frozen)
}

@Test func elevenIdenticalHoursIsNotYetFrozen() {
    let same = Array(repeating: 33.0, count: 10)
    #expect(QualityChecker.check(observation(source: "waqi", ageHours: 1.1, pm25: 33),
                                 fetchedAt: now, previousValues: same) == .ok)
}

@Test func changedValueBreaksFrozenRun() {
    let same = Array(repeating: 33.0, count: 11)
    #expect(QualityChecker.check(observation(source: "waqi", ageHours: 1.1, pm25: 35),
                                 fetchedAt: now, previousValues: same) == .ok)
}
