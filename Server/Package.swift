// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "Server",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.99.0"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.9.0"),
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.8.0"),
        .package(path: "../AirCore")
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                .product(name: "AirCore", package: "AirCore"),
            ]
        ),
        .testTarget(
            name: "AppTests",
            dependencies: ["App", .product(name: "XCTVapor", package: "vapor")]
        ),
    ],
    swiftLanguageModes: [.v5]
)
