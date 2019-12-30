// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "VaporOpenAPI",
    platforms: [
        .macOS(.v10_14)
    ],
    products: [
        .library(
            name: "VaporOpenAPI",
            targets: ["VaporOpenAPI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0-alpha.3"),
        .package(url: "https://github.com/mattpolzin/VaporTypedRoutes.git", .upToNextMinor(from: "0.1.0")),
        .package(url: "https://github.com/mattpolzin/OpenAPI.git", .upToNextMinor(from: "0.10.0")),
    ],
    targets: [
        .target(
            name: "VaporOpenAPI",
            dependencies: ["Vapor", "VaporTypedRoutes", "OpenAPIKit"]),
        .testTarget(
            name: "VaporOpenAPITests",
            dependencies: ["VaporOpenAPI", "XCTVapor"]),
    ]
)
