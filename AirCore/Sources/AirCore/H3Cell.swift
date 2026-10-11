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
        guard let value = UInt64(hex, radix: 16), isValidCell(value) == 1 else { return  nil }
        self.rawValue = value
    }

    public init(postgresValue: Int64) {
        rawValue = UInt64(bitPattern: postgresValue)
    }

    public var resolution: Int { Int(getResolution(rawValue)) }
    public var hex: String { String(rawValue, radix: 16) }
    public var postgresValue: Int64 { Int64(bitPattern: rawValue) }

    public var center: Coordinate {
        get throws {
            var point = LatLng(lat: 0, lng: 0)
            let code = cellToLatLng(rawValue, &point)
            guard code == 0 else { throw H3Failure(code: code) }
            return Coordinate(latitude: radsToDegs(point.lat),
                              longitude: radsToDegs(point.lng))
        }
    }

    // MARK: - Neighbors
    /// Semua sel dalam jarak k langkah, termasuk sel ini sendiri.
    /// k = 1 -> 7 sel, k = 2 -> 19 sel (lebih sedikit di dekat pentagon).
    public func disk(k: Int) throws -> [H3Cell] {
        // 1) Tanya ukuran maksimum hasilnya
        var size: Int64 = 0
        let sizeCode = maxGridDiskSize(Int32(k), &size)
        guard sizeCode == 0 else { throw H3Failure(code: sizeCode) }
        
        // 2) Siapkan buffer berisi 0, biarkan C mengisinya
        var buffer = [H3Index](repeating: 0, count: Int(size))
        let diskCode = gridDisk(rawValue, Int32(k), &buffer)
        guard diskCode == 0 else { throw H3Failure(code: diskCode) }
        
        // 3) Slot yang tidak terpakai tetap 0, buang
        return buffer.filter { $0 != 0 }.map { H3Cell(rawValue: $0) }
    }
    
    // Init internal untuk membungkus nilai yang sudah pasti sah (dari hasil C).
    private init(rawValue: UInt64) {
        self.rawValue = rawValue
    }
}
