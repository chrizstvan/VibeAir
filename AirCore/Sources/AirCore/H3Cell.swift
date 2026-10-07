//
//  File.swift
//  AirCore
//
//  Created by Christian Stevanus on 04/10/26.
//

import Foundation
internal import CH3

public struct H3Failure: Error, Equatable {
    public let code: UInt32
    public init(code: UInt32) { self.code = code }
}

public struct H3Cell: Sendable, Hashable, Codable {
    public let rawValue: UInt64

    public init(containing coordinate: Coordinate, resolution: Int) throws {
        var point = LatLng(lat: degsToRads(coordinate.latitude),
                           lng: degsToRads(coordinate.longitude))
        var index: H3Index = .zero
        let code = latLngToCell(&point, Int32(resolution), &index)
        guard code == .zero else { throw H3Failure(code: code) }
        self.rawValue = index
    }

    public init?(hex: String) {
        fatalError("belum diisi")
    }

    public init(postgresValue: Int64) {
        fatalError("belum diisi")
    }

    public var resolution: Int { fatalError("belum diisi") }
    public var hex: String { fatalError("belum diisi") }
    public var postgresValue: Int64 { fatalError("belum diisi") }

    public var center: Coordinate {
        get throws { fatalError("belum diisi") }
    }

    public func disk(k: Int) throws -> [H3Cell] {
        fatalError("belum diisi")
    }
}
