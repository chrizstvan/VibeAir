//
//  File.swift
//  Server
//
//  Created by Christian Stevanus on 19/11/26.
//

import Vapor
import AirCore

enum StationKind: String {
    case referenceHourly = "reference_hourly"
    case referenceDaily = "reference_daily"
    case lowCost = "low_cost"
    case unknown
}

struct Region {
    let minLat = -6.6, maxLat = -6.0, minLon = 106.4, maxLon = 107.2
    func contains(_ c: Coordinate) -> Bool {
        (minLat...maxLat).contains(c.latitude) && (minLon...maxLon).contains(c.longitude)
    }
}

struct Observation {
    let sourceID: String
    let externalID: String
    let name: String?
    let owner: String?
    let coordinate: Coordinate
    let kind: StationKind
    let measuredAt: Date
    let pm25: Double          // µg/m³, not calibration
    let aqiReported: Int?     // for WAQI
    let humidity: Double?     // for AirGradient
}

protocol SourceAdapter {
    var sourceID: String { get }
    func fetch(client: any Client, logger: Logger) async throws -> [Observation]
}
