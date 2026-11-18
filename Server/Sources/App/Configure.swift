//
//  File.swift
//  Server
//
//  Created by Christian Stevanus on 06/11/26.
//

import Vapor
import Fluent
import FluentPostgresDriver
import NIOSSL

let DATABASE_URL = "DATABASE_URL"

func configure(_ app: Application) async throws {
    guard let databaseURL = Environment.get(DATABASE_URL) else {
        throw Abort(.internalServerError, reason: "DATABASE URL not yet set")
    }
    var config = try SQLPostgresConfiguration(url: databaseURL)
    if !databaseURL.contains("localhost") {
        var tls = TLSConfiguration.makeClientConfiguration()
        tls.trustRoots = .file("certs/prod-ca-2021.crt")
        config.coreConfiguration.tls = .require(try NIOSSLContext(configuration: tls))
    }
    app.databases.use(.postgres(configuration: config), as: .psql)
    
    app.migrations.add(CreateSchema())
    app.asyncCommands.use(RunCycleCommand(), as: "run-cycle")
}
