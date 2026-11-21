//
//  File.swift
//  Server
//
//  Created by Christian Stevanus on 19/11/26.
//

import Vapor
import AirCore

struct AirGradientItem: Decodable {
    let locationId: Int
    let locationName: String?
    let latitude: Double?
    let longitude: Double?
    let pm02: Double?
    let rhum: Double?
    let timestamp: String?
    let offline: Bool?
}

struct AirGradientAdapter: SourceAdapter {
    let sourceID = "airgradient"
    let region = Region()

    func fetch(client: any Client, logger: Logger) async throws -> [Observation] {
        let uri = URI(string: "https://api.airgradient.com/public/api/v1/world/locations/measures/current")
        let response = try await client.get(uri)
        guard response.status == .ok else {
            throw Abort(.badGateway, reason: "AirGradient HTTP \(response.status.code)")
        }
        let items = try response.content.decode([AirGradientItem].self)
        return observations(from: items)
    }

    func observations(from items: [AirGradientItem]) -> [Observation] {
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let plain = ISO8601DateFormatter()

        return items.compactMap { item in
            guard item.offline != true,
                  let lat = item.latitude, let lon = item.longitude,
                  let pm25 = item.pm02,
                  let stamp = item.timestamp,
                  let measuredAt = withFraction.date(from: stamp) ?? plain.date(from: stamp)
            else { return nil }

            let coordinate = Coordinate(latitude: lat, longitude: lon)
            guard region.contains(coordinate) else { return nil }

            return Observation(
                sourceID: sourceID,
                externalID: String(item.locationId),
                name: item.locationName,
                owner: nil,
                coordinate: coordinate,
                kind: .lowCost,
                measuredAt: measuredAt,
                pm25: pm25,
                aqiReported: nil,
                humidity: item.rhum
            )
        }
    }
}
