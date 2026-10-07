//
//  File.swift
//  AirCore
//
//  Created by Christian Stevanus on 04/10/26.
//

import Foundation
import Testing
import AirCore

struct Fixture: Decodable {
    struct Cell: Decodable {
        let name: String, lat: Double, lon: Double, res: Int
        let cell_hex: String, cell_uint64: String
        let center_lat: Double, center_lon: Double
        let disk1: [String]
    }
    let cells: [Cell]
    
    static func load() throws -> Fixture {
        let url = try #require(Bundle.module.url(
            forResource: "h3_cells", withExtension: "json", subdirectory: "Fixtures"))
        return try JSONDecoder().decode(Fixture.self, from: Data(contentsOf: url))
    }
}

@Test func cellsMatchReference() throws {
    for c in try Fixture.load().cells {
        let cell = try H3Cell(containing: Coordinate(latitude: c.lat, longitude: c.lon),
                              resolution: c.res)
        #expect(cell.rawValue == UInt64(c.cell_uint64), "\(c.name) res \(c.res)")
        #expect(cell.hex == c.cell_hex)
    }
}
