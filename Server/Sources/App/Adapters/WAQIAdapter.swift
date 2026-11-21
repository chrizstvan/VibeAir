//
//  File.swift
//  Server
//
//  Created by Christian Stevanus on 19/11/26.
//

import Vapor
import AirCore

struct WAQIBoundsResponse: Decodable {
    let data: [Station]
    struct Station: Decodable {
        let uid: Int
    }
}

struct WAQIFeedResponse: Decodable {
    let status: String
    let data: FeedData?
    
    struct FeedData: Decodable {
        let idx: Int
        let city: City
        let iaqi: [String: Value]
        let time: Time
        let attributions: [Attribution]
    }
    
    struct City: Decodable { let name: String; let geo: [Double] }
    struct Time: Decodable { let iso: String }
    struct Attribution: Decodable { let name: String }
    struct Value: Decodable {
        let v: Double?
        enum CodingKeys: String, CodingKey { case v }
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            v = try? container.decode(Double.self, forKey: .v)
        }
    }
    
    enum CodingKeys: String, CodingKey { case status, data }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = try container.decode(String.self, forKey: .status)
        data = try? container.decode(FeedData.self, forKey: .data)
    }
}

struct WAQIAdapter: SourceAdapter {
    let sourceID: String = "waqi"
    let token: String
    let region: Region = .init()
    let hourlyReferenceUIDs: Set<Int>
    
    func fetch(client: any Vapor.Client, logger: Logging.Logger) async throws -> [Observation] {
        let box = "\(region.minLat),\(region.minLon),\(region.maxLat),\(region.maxLon)"
        let boundsURI = URI(string: "https://api.waqi.info/v2/map/bounds?latlng=\(box)&networks=all&token=\(token)")
        let bounds = try await client.get(boundsURI).content.decode(WAQIBoundsResponse.self)
        
        let iso = ISO8601DateFormatter()
        var observations: [Observation] = []
        for station in bounds.data {
            let feedURI = URI(string: "https://api.waqi.info/feed/@\(station.uid)/?token=\(token)")
            guard let feed = try? await client.get(feedURI).content.decode(WAQIFeedResponse.self),
                  feed.status == "ok", let data = feed.data, data.city.geo.count == 2,
                  let aqi = data.iaqi["pm25"]?.v,
                  let pm25 = PM25.concentration(fromAQI: aqi),
                  let measuredAt = iso.date(from: data.time.iso) else {
                logger.warning("WAQI uid \(station.uid) dilewati")
                continue
            }
            let owner = data.attributions.first?.name
            observations.append(Observation(
                sourceID: sourceID,
                externalID: String(data.idx),
                name: data.city.name,
                owner: owner,
                coordinate: Coordinate(latitude: data.city.geo[0], longitude: data.city.geo[1]),
                kind: kind(uid: data.idx, owner: owner),
                measuredAt: measuredAt,
                pm25: pm25,
                aqiReported: Int(aqi),
                humidity: nil
            ))
            try await Task.sleep(for: .seconds(1))
        }
        return observations
    }

    private func kind(uid: Int, owner: String?) -> StationKind {
        if hourlyReferenceUIDs.contains(uid) { return .referenceHourly }
        if owner?.contains("Lingkungan Hidup") == true { return .referenceDaily }
        return .unknown
    }
}
