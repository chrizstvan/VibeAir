//
//  File.swift
//  Server
//
//  Created by Christian Stevanus on 06/11/26.
//

import Vapor
import Fluent
import SQLKit
import AirCore

struct RunCycleCommand: AsyncCommand {
    struct Signature: CommandSignature {}
    var help: String { "Fetch, check, and store data for this hour" }

    func run(using context: CommandContext, signature: Signature) async throws {
        let app = context.application
        let sql = app.db as! SQLDatabase
        let logger = app.logger
        let fetchedAt = Date()
        let scheduledFor = Self.hourStart(of: fetchedAt)

        guard let cycleID = try await claimCycle(sql, scheduledFor: scheduledFor) else {
            logger.info("cycle \(scheduledFor) are climed, out")
            return
        }

        do {
            var observations: [Observation] = []
            for adapter in try makeAdapters() {
                do {
                    observations += try await adapter.fetch(client: app.client, logger: logger)
                } catch {
                    logger.error("Adapter \(adapter.sourceID) error: \(error)")
                }
            }
            guard !observations.isEmpty else {
                throw Abort(.badGateway, reason: "No data from any source")
            }

            var inserted = 0
            for observation in observations {
                let stationID = try await upsertStation(sql, observation, seenAt: fetchedAt)
                let previous = try await previousValues(sql, stationID: stationID, before: observation.measuredAt)
                let quality = QualityChecker.check(observation, fetchedAt: fetchedAt, previousValues: previous)
                inserted += try await insertReading(sql, stationID: stationID, observation,
                                                    quality: quality, fetchedAt: fetchedAt, cycleID: cycleID)
            }

            try await logMissingStations(sql, fetchedAt: fetchedAt, logger: logger)
            try await finish(sql, cycleID: cycleID, status: "succeeded",
                             seen: observations.count, inserted: inserted, error: nil)
            logger.info("Cycle completed: \(observations.count) readings, \(inserted) new")
        } catch {
            try? await finish(sql, cycleID: cycleID, status: "failed",
                              seen: nil, inserted: nil, error: String(describing: error))
            throw error
        }
    }

    static func hourStart(of date: Date) -> Date {
        Date(timeIntervalSince1970: (date.timeIntervalSince1970 / 3600).rounded(.down) * 3600)
    }

    private func makeAdapters() throws -> [any SourceAdapter] {
        guard let token = Environment.get("WAQI_TOKEN") else {
            throw Abort(.internalServerError, reason: "WAQI_TOKEN are not seted")
        }
        return [WAQIAdapter(token: token, hourlyReferenceUIDs: [8294]), AirGradientAdapter()]
    }

    private func claimCycle(_ sql: SQLDatabase, scheduledFor: Date) async throws -> Int? {
        let row = try await sql.raw("""
            insert into cycles (scheduled_for) values (\(bind: scheduledFor))
            on conflict (scheduled_for) do update
                set status = 'running', started_at = now(), finished_at = null, error = null
                where cycles.status = 'failed'
            returning id
            """).first()
        return try row?.decode(column: "id", as: Int.self)
    }

    private func upsertStation(_ sql: SQLDatabase, _ obs: Observation, seenAt: Date) async throws -> Int {
        let cell = try H3Cell(containing: obs.coordinate, resolution: 7)
        let row = try await sql.raw("""
            insert into stations (source_id, external_id, name, owner, kind, location, h3_res7, last_seen_at)
            values (\(bind: obs.sourceID), \(bind: obs.externalID), \(bind: obs.name), \(bind: obs.owner),
                    \(bind: obs.kind.rawValue),
                    ST_SetSRID(ST_MakePoint(\(bind: obs.coordinate.longitude), \(bind: obs.coordinate.latitude)), 4326)::geography,
                    \(bind: cell.postgresValue), \(bind: seenAt))
            on conflict (source_id, external_id) do update set
                name = excluded.name, owner = excluded.owner, kind = excluded.kind,
                location = excluded.location, h3_res7 = excluded.h3_res7,
                last_seen_at = excluded.last_seen_at
            returning id
            """).first()
        guard let id = try row?.decode(column: "id", as: Int.self) else {
            throw Abort(.internalServerError, reason: "Upsert stasiun tidak mengembalikan id")
        }
        return id
    }

    private func previousValues(_ sql: SQLDatabase, stationID: Int, before: Date) async throws -> [Double] {
        let limit = QualityRules.current.frozenAfterHours - 1
        let rows = try await sql.raw("""
            select pm25 from readings
            where station_id = \(bind: stationID)
              and measured_at < \(bind: before)
              and measured_at > \(bind: before.addingTimeInterval(-14 * 3600))
            order by measured_at desc
            limit \(bind: limit)
            """).all()
        return try rows.map { try $0.decode(column: "pm25", as: Double.self) }
    }

    private func insertReading(_ sql: SQLDatabase, stationID: Int, _ obs: Observation,
                               quality: Quality, fetchedAt: Date, cycleID: Int) async throws -> Int {
        let rows = try await sql.raw("""
            insert into readings (station_id, measured_at, pm25, aqi_reported, humidity,
                                  quality, fetched_at, cycle_id)
            values (\(bind: stationID), \(bind: obs.measuredAt), \(bind: obs.pm25), \(bind: obs.aqiReported),
                    \(bind: obs.humidity), \(bind: quality.rawValue), \(bind: fetchedAt), \(bind: cycleID))
            on conflict (station_id, measured_at) do nothing
            returning station_id
            """).all()
        return rows.count
    }

    private func logMissingStations(_ sql: SQLDatabase, fetchedAt: Date, logger: Logger) async throws {
        let rows = try await sql.raw("""
            select source_id, name from stations
            where last_seen_at < \(bind: fetchedAt)
              and last_seen_at > \(bind: fetchedAt.addingTimeInterval(-24 * 3600))
            """).all()
        for row in rows {
            let name = (try? row.decode(column: "name", as: String?.self)) ?? nil
            logger.warning("station not exist on this hours: \(name ?? "no name")")
        }
    }

    private func finish(_ sql: SQLDatabase, cycleID: Int, status: String,
                        seen: Int?, inserted: Int?, error: String?) async throws {
        try await sql.raw("""
            update cycles set finished_at = now(), status = \(bind: status),
                stations_seen = \(bind: seen), readings_inserted = \(bind: inserted), error = \(bind: error)
            where id = \(bind: cycleID)
            """).run()
    }
}
