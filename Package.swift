// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "VaporOpenAPI",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "VaporOpenAPI",
            targets: ["VaporOpenAPI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", .upToNextMajor(from: "4.4.0")),
        .package(url: "https://github.com/mattpolzin/VaporTypedRoutes.git", .upToNextMinor(from: "0.4.0")),
        .package(url: "https://github.com/mattpolzin/OpenAPIKit.git", .upToNextMinor(from: "0.29.0")),
        .package(url: "https://github.com/mattpolzin/OpenAPIReflection.git", .upToNextMinor(from: "0.1.0")),
    ],
    targets: [
        .target(
            name: "VaporOpenAPI",
            dependencies: [.product(name: "Vapor", package: "vapor"), "VaporTypedRoutes", "OpenAPIKit", "OpenAPIReflection"]),
        .testTarget(
            name: "VaporOpenAPITests",
            dependencies: ["VaporOpenAPI", .product(name: "XCTVapor", package: "vapor")]),
    ]
)
