//
//  File.swift
//  Server
//
//  Created by Christian Stevanus on 19/11/26.
//

import Testing
@testable import App

private func item(id: Int, lat: Double, lon: Double, pm02: Double?, offline: Bool? = false,
                  timestamp: String = "2026-11-03T03:07:29.000Z") -> AirGradientItem {
    AirGradientItem(locationId: id, locationName: "Test \(id)", latitude: lat, longitude: lon,
                    pm02: pm02, rhum: 70, timestamp: timestamp, offline: offline)
}

@Test func keepsOnlyOnlineSensorsInsideRegion() {
    let items = [
        item(id: 1, lat: -6.2, lon: 106.8, pm02: 50),                   // masuk
        item(id: 2, lat: 1.3, lon: 103.8, pm02: 30),                    // di luar wilayah
        item(id: 3, lat: -6.3, lon: 106.9, pm02: 45, offline: true),    // offline
        item(id: 4, lat: -6.25, lon: 106.85, pm02: nil),                // tanpa PM2.5
        item(id: 5, lat: -6.15, lon: 106.82, pm02: 60,
             timestamp: "2026-11-03T03:07:29Z"),                       // tanpa pecahan detik, tetap masuk
    ]
    let result = AirGradientAdapter().observations(from: items)
    #expect(result.map(\.externalID) == ["1", "5"])
    #expect(result.allSatisfy { $0.kind == .lowCost && $0.humidity == 70 })
}
