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

let DATABASE_URL = "DATABASE_URL_DEV"

func configure(_ app: Application) async throws {
    guard let databaseURL = Environment.get(DATABASE_URL) else {
        throw Abort(.internalServerError, reason: "DATABASE URL not yet set")
    }
    var config = try SQLPostgresConfiguration(url: databaseURL)
    if !databaseURL.contains("localhost") {
        config.coreConfiguration.tls = .require(try NIOSSLContext(configuration: .clientDefault))
    }
    app.databases.use(.postgres(configuration: config), as: .psql)
    
//    app.migrations.add(CreateSchema())   // dibuka di langkah 3
    app.asyncCommands.use(RunCycleCommand(), as: "run-cycle")
}
