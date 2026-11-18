import Fluent
import SQLKit

struct CreateSchema: AsyncMigration {
    func prepare(on database: Database) async throws {
            let sql = database as! SQLDatabase
            for statement in Self.statements {
                try await sql.raw(SQLQueryString(statement)).run()
            }
        }

        func revert(on database: Database) async throws {
            let sql = database as! SQLDatabase
            for table in ["readings", "calibration_factors", "cycles", "stations", "sources"] {
                let statement = "drop table if exists \(table) cascade"
                try await sql.raw(SQLQueryString(statement)).run()
            }
        }
    
    static let statements: [String] = [
        "create extension if not exists postgis",
            """
            create table sources (
                id text primary key,
                is_public boolean not null,
                attribution text not null
            )
            """,
            """
            create table stations (
                id bigserial primary key,
                source_id text not null references sources(id),
                external_id text not null,
                name text,
                owner text,
                kind text not null default 'unknown'
                    check (kind in ('reference_hourly', 'reference_daily', 'low_cost', 'unknown')),
                location geography(point, 4326) not null,
                h3_res7 bigint not null,
                first_seen_at timestamptz not null default now(),
                last_seen_at timestamptz not null default now(),
                unique (source_id, external_id)
            )
            """,
        "create index stations_location_idx on stations using gist (location)",
        "create index stations_h3_idx on stations (h3_res7)",
            """
            create table cycles (
                id bigserial primary key,
                scheduled_for timestamptz not null unique,
                started_at timestamptz not null default now(),
                finished_at timestamptz,
                status text not null default 'running'
                    check (status in ('running', 'succeeded', 'failed')),
                stations_seen integer,
                readings_inserted integer,
                error text
            )
            """,
            """
            create table readings (
                station_id bigint not null references stations(id),
                measured_at timestamptz not null,
                pm25 double precision not null,
                aqi_reported integer,
                humidity double precision,
                quality text not null check (quality in ('ok', 'stale', 'frozen')),
                fetched_at timestamptz not null,
                cycle_id bigint not null references cycles(id),
                primary key (station_id, measured_at)
            )
            """,
        "create index readings_measured_idx on readings (measured_at)",
            """
            create table calibration_factors (
                source_id text not null references sources(id),
                valid_from timestamptz not null,
                divide_by double precision not null check (divide_by > 0),
                reference text not null,
                note text,
                primary key (source_id, valid_from)
            )
            """,
            """
            insert into sources (id, is_public, attribution) values
                ('waqi', false, 'World Air Quality Index Project dan lembaga asal'),
                ('airgradient', false, 'AirGradient')
            """,
            """
            insert into calibration_factors (source_id, valid_from, divide_by, reference, note) values
                ('airgradient', '2026-10-11T00:00:00Z', 1.37, 'BMKG Kemayoran (WAQI 8294)',
                 'Evaluasi tahap 2, periode latih 11 sampai 24 Okt')
            """,
        "alter table sources enable row level security",
        "alter table stations enable row level security",
        "alter table cycles enable row level security",
        "alter table readings enable row level security",
        "alter table calibration_factors enable row level security",
    ]
}
