// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AirCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "AirCore", targets: ["AirCore"])],
    targets: [
        .target(
            name: "CH3",
            exclude: ["LICENSE-H3"],
            cSettings: [.headerSearchPath("internal")],
            linkerSettings: [.linkedLibrary("m", .when(platforms: [.linux]))]
        ),
        .target(name: "AirCore", dependencies: ["CH3"]),
        .testTarget(
            name: "AirCoreTests",
            dependencies: ["AirCore", "CH3"],
            resources: [.copy("Fixtures")]
        ),
    ]
)