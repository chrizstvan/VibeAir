//
//  File.swift
//  Server
//
//  Created by Christian Stevanus on 06/11/26.
//

import Vapor

struct RunCycleCommand: AsyncCommand {
    struct Signature: CommandSignature {}
    var help: String {"Get, check, and store data for this hours"}
    
    func run(using context: CommandContext, signature: Signature) async throws {
        context.console.print("run-cycle not yet filled")
    }
}
