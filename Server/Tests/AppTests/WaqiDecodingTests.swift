//
//  File.swift
//  Server
//
//  Created by Christian Stevanus on 19/11/26.
//

import Testing
import Foundation
import AirCore
@testable import App

private func fixture(_ name: String) throws -> Data {
    let url = try #require(
        Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures")
    )
    return try Data(contentsOf: url)
}

@Test func decodesOkFeed() throws {
    let feed = try JSONDecoder().decode(WAQIFeedResponse.self, from: fixture("waqi_feed"))
    let data = try #require(feed.data)

    #expect(feed.status == "ok")
    #expect(data.idx == -900001)
    #expect(data.city.name == "Stasiun Contoh Selatan")
    #expect(data.city.geo == [-6.25, 106.8])
    #expect(data.iaqi["pm25"]?.v == 95)
    #expect(data.attributions.first?.name == "Lembaga Contoh")
    #expect(ISO8601DateFormatter().date(from: data.time.iso) != nil)
}

@Test func nonNumericValueBecomesNil() throws {
    let feed = try JSONDecoder().decode(WAQIFeedResponse.self, from: fixture("waqi_feed"))
    let data = try #require(feed.data)

    #expect(data.iaqi["co"] != nil)
    #expect(data.iaqi["co"]?.v == nil)
}

@Test func errorFeedHasNoData() throws {
    let feed = try JSONDecoder().decode(WAQIFeedResponse.self, from: fixture("waqi_feed_error"))

    #expect(feed.status == "error")
    #expect(feed.data == nil)
}

@Test func fixtureAQIConvertsToConcentration() throws {
    let feed = try JSONDecoder().decode(WAQIFeedResponse.self, from: fixture("waqi_feed"))
    let aqi = try #require(feed.data?.iaqi["pm25"]?.v)
    let pm25 = try #require(PM25.concentration(fromAQI: aqi))

    #expect(abs(pm25 - 33.02) < 0.01)
}
