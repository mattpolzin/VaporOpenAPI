// swift-tools-version:5.2

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
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0-beta.3.24"),
        .package(url: "https://github.com/mattpolzin/VaporTypedRoutes.git", .upToNextMinor(from: "0.2.0")),
        .package(url: "https://github.com/mattpolzin/OpenAPIKit.git", .upToNextMinor(from: "0.20.0")),
    ],
    targets: [
        .target(
            name: "VaporOpenAPI",
            dependencies: [.product(name: "Vapor", package: "vapor"), "VaporTypedRoutes", "OpenAPIKit"]),
        .testTarget(
            name: "VaporOpenAPITests",
            dependencies: ["VaporOpenAPI", .product(name: "XCTVapor", package: "vapor")]),
    ]
)
